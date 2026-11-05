param([Parameter(Mandatory = $true)][string]$Makensis)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$testRoot = Join-Path $env:TEMP ('rvm-installer-failure-' + [Guid]::NewGuid().ToString('N'))
$package = Join-Path $testRoot 'package'
$profileHome = Join-Path $testRoot 'profile'
New-Item -ItemType Directory -Force -Path (Join-Path $package 'bin'),(Join-Path $package 'src\templates'),$profileHome | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $package 'src\tools\path') | Out-Null
[IO.File]::WriteAllText((Join-Path $package 'src\templates\rvm.cmd'),'new-template')
[IO.File]::WriteAllText((Join-Path $package 'src\templates\new.cmd'),'new-package-file')
$fixture = Join-Path $package 'bin\rvm.exe'
& crystal build (Join-Path $repo 'spec\support\installer_failure_fixture.cr') --release -o $fixture
if ($LASTEXITCODE -ne 0) { throw 'Fixture build failed.' }
Copy-Item -LiteralPath (Join-Path $repo 'src\tools\path\package_path.ps1') -Destination (Join-Path $package 'src\tools\path\package_path.ps1')
$setup = Join-Path $testRoot 'fixture-setup.exe'
& $Makensis /INPUTCHARSET UTF8 /DVERSION=9.99.97 /DFILE_VERSION=9.99.97.0 "/DPACKAGE_DIR=$package" "/DOUTPUT_FILE=$setup" (Join-Path $repo 'installer\rvm-windows.nsi')
if ($LASTEXITCODE -ne 0) { throw 'Fixture installer build failed.' }
$config = Join-Path $env:USERPROFILE '.rvm.json'
$configHash = if (Test-Path -LiteralPath $config) { (Get-FileHash -Algorithm SHA256 $config).Hash } else { $null }
$key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
try {
    $originalPath = [string]$key.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $originalKind = $key.GetValueKind('Path')
} finally { $key.Close() }
$registryKeys=@('HKCU\Software\rvm-windows.cr','HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr')
$registryPsPaths=@('HKCU:\Software\rvm-windows.cr','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr')
$registryExisted=@()
for($i=0;$i -lt $registryKeys.Count;$i++){
    $registryExisted+=Test-Path -LiteralPath $registryPsPaths[$i]
    if($registryExisted[$i]){ & reg.exe export $registryKeys[$i] (Join-Path $testRoot "$i.reg") /y | Out-Null; if($LASTEXITCODE -ne 0){ throw 'Host registry backup failed.' } }
}
$env:RVM_HOME = $profileHome
try {
    foreach ($mode in @('preflight','prepare','deployment','locked','interrupted','interrupted-retry')) {
        Write-Output "RUNNING_INSTALLER_FIXTURE=$mode"
        $target = Join-Path $testRoot $mode
        New-Item -ItemType Directory -Force -Path (Join-Path $target 'bin'),(Join-Path $target 'src\templates') | Out-Null
        $oldExe = Join-Path $target 'bin\rvm.exe'
        [IO.File]::WriteAllText($oldExe,'original-executable')
        [IO.File]::WriteAllText((Join-Path $target 'src\templates\rvm.cmd'),'old-template')
        [IO.File]::WriteAllText((Join-Path $target 'user-marker.txt'),'keep-user-file')
        if ($mode -in @('interrupted','interrupted-retry')) {
            $backup = Join-Path $testRoot ($mode + '-backup')
            & (Join-Path $repo 'src\tools\path\package_transaction.ps1') -Action snapshot -Stage $package -Target $target -Backup $backup
            & (Join-Path $repo 'src\tools\path\package_transaction.ps1') -Action deploy -Stage $package -Target $target -Backup $backup
        }
        if($mode -eq 'interrupted-retry') { Remove-Item Env:RVM_TEST_INSTALLER_FAILURE -ErrorAction SilentlyContinue }
        else { $env:RVM_TEST_INSTALLER_FAILURE = if ($mode -eq 'locked') { 'deployment' } elseif ($mode -in @('interrupted','interrupted-retry')) { 'prepare' } else { $mode } }
        $lock = $null
        try {
            if ($mode -eq 'locked') { $lock = [IO.File]::Open($oldExe,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read) }
            $process = Start-Process -FilePath $setup -ArgumentList "/S /D=$target" -PassThru
            if (-not $process.WaitForExit(30000)) {
                Write-Output "FIXTURE_TIMEOUT_PID=$($process.Id) MODE=$mode TARGET=$target"
                $allProcesses = @(Get-CimInstance Win32_Process)
                $parentIds = @($process.Id)
                while ($parentIds.Count -gt 0) {
                    $children = @($allProcesses | Where-Object { $_.ParentProcessId -in $parentIds })
                    $children | Select-Object ProcessId,ParentProcessId,Name,CommandLine | Format-List | Out-String | Write-Output
                    $parentIds = @($children | ForEach-Object { $_.ProcessId })
                }
                Get-ChildItem -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue | Select-Object FullName,Length | Format-Table -AutoSize | Out-String | Write-Output
                $marker = Join-Path $target '.rvm-package-transaction'
                if (Test-Path -LiteralPath $marker -PathType Leaf) {
                    $transactionBackup = [IO.File]::ReadAllText($marker,[Text.Encoding]::UTF8)
                    Write-Output "FIXTURE_TRANSACTION_BACKUP=$transactionBackup"
                    Get-ChildItem -LiteralPath $transactionBackup -Force -ErrorAction SilentlyContinue | Select-Object Name,Length | Format-Table -AutoSize | Out-String | Write-Output
                }
                $process.Kill()
                $process.WaitForExit()
                throw "Fixture installer hung during $mode."
            }
            if ($mode -eq 'interrupted-retry') {
                if ($process.ExitCode -ne 0) { throw 'Setup did not continue after interrupted transaction recovery.' }
            } elseif ($process.ExitCode -eq 0) { throw "Fixture installer unexpectedly succeeded during $mode." }
        } catch {
            Write-Error "INSTALLER_FIXTURE_FAILED=$mode`n$($_.Exception.ToString())"
            throw
        } finally { if ($lock) { $lock.Dispose() } }
        if($mode -eq 'interrupted-retry') {
            if(-not (Test-Path (Join-Path $target 'src\tools\path\package_path.ps1')) -or (Test-Path (Join-Path $target '.rvm-package-transaction'))){throw 'Retried setup did not complete cleanly after recovery.'}
            Write-Output "PASS $mode"
            continue
        }
        if ([IO.File]::ReadAllText($oldExe) -cne 'original-executable') { throw "Original executable not preserved during $mode." }
        if ([IO.File]::ReadAllText((Join-Path $target 'src\templates\rvm.cmd')) -cne 'old-template') { throw "Original template not restored during $mode." }
        if (Test-Path -LiteralPath (Join-Path $target 'src\templates\new.cmd')) { throw "New package file remained after $mode." }
        $marker = Join-Path $target '.rvm-package-transaction'
        if ($mode -eq 'locked') {
            if (-not (Test-Path -LiteralPath $marker)) { throw 'Locked-file failure did not retain its recovery marker.' }
            $backupPath = [IO.File]::ReadAllText($marker,[Text.Encoding]::UTF8)
            if (-not (Test-Path -LiteralPath (Join-Path $backupPath 'manifest.json'))) { throw 'Locked-file recovery backup is missing.' }
        } elseif ($mode -eq 'interrupted') {
            if (Test-Path -LiteralPath $marker) { throw 'Interrupted package transaction was not recovered before retry.' }
        } elseif (Test-Path -LiteralPath $marker) { throw "Successful rollback left a pending marker during $mode." }
        if ([IO.File]::ReadAllText((Join-Path $target 'user-marker.txt')) -cne 'keep-user-file') { throw "User marker changed during $mode." }
        Write-Output "PASS $mode"
    }
} finally {
    Remove-Item Env:RVM_TEST_INSTALLER_FAILURE -ErrorAction SilentlyContinue
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
    try {
        $finalPath = [string]$key.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $finalKind = $key.GetValueKind('Path')
    } finally { $key.Close() }
    if ($finalPath -cne $originalPath -or $finalKind -ne $originalKind) {
        $key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
        try { $key.SetValue('Path',$originalPath,$originalKind) } finally { $key.Close() }
    }
    if ($configHash -and (Get-FileHash -Algorithm SHA256 $config).Hash -ne $configHash) { throw 'Host RVM config unexpectedly changed.' }
    for($i=0;$i -lt $registryKeys.Count;$i++){
        if($registryExisted[$i]){
            & reg.exe import (Join-Path $testRoot "$i.reg") | Out-Null
            if($LASTEXITCODE -ne 0){throw 'Host registry restoration failed.'}
        } elseif(Test-Path -LiteralPath $registryPsPaths[$i]) {
            Remove-Item -LiteralPath $registryPsPaths[$i] -Recurse -Force
        }
    }
    Write-Output "TEST_DATA_RETAINED=$testRoot"
}
