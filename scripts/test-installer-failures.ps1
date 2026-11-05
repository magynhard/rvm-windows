param([Parameter(Mandatory = $true)][string]$Makensis)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$testRoot = Join-Path $env:TEMP ('rvm-installer-failure-' + [Guid]::NewGuid().ToString('N'))
$package = Join-Path $testRoot 'package'
$profileHome = Join-Path $testRoot 'profile'
New-Item -ItemType Directory -Force -Path (Join-Path $package 'bin'),$profileHome | Out-Null
$fixture = Join-Path $package 'bin\rvm.exe'
& crystal build (Join-Path $repo 'spec\support\installer_failure_fixture.cr') --release --static -o $fixture
if ($LASTEXITCODE -ne 0) { throw 'Fixture build failed.' }
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
$env:RVM_HOME = $profileHome
try {
    foreach ($mode in @('preflight','prepare','deployment','locked')) {
        $target = Join-Path $testRoot $mode
        New-Item -ItemType Directory -Force -Path (Join-Path $target 'bin') | Out-Null
        $oldExe = Join-Path $target 'bin\rvm.exe'
        [IO.File]::WriteAllText($oldExe,'original-executable')
        [IO.File]::WriteAllText((Join-Path $target 'user-marker.txt'),'keep-user-file')
        $env:RVM_TEST_INSTALLER_FAILURE = if ($mode -eq 'locked') { 'deployment' } else { $mode }
        $lock = $null
        try {
            if ($mode -eq 'locked') { $lock = [IO.File]::Open($oldExe,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read) }
            $process = Start-Process -FilePath $setup -ArgumentList "/S /D=$target" -PassThru
            if (-not $process.WaitForExit(30000)) {
                $process.Kill()
                $process.WaitForExit()
                throw "Fixture installer hung during $mode."
            }
            if ($process.ExitCode -eq 0) { throw "Fixture installer unexpectedly succeeded during $mode." }
        } finally { if ($lock) { $lock.Dispose() } }
        if ([IO.File]::ReadAllText($oldExe) -cne 'original-executable') { throw "Original executable not preserved during $mode." }
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
    if ($finalPath -cne $originalPath -or $finalKind -ne $originalKind) { throw 'Host user PATH unexpectedly changed.' }
    if ($configHash -and (Get-FileHash -Algorithm SHA256 $config).Hash -ne $configHash) { throw 'Host RVM config unexpectedly changed.' }
    Write-Output "TEST_DATA_RETAINED=$testRoot"
}
