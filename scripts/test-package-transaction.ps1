$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$helper = Join-Path $repo 'src\tools\path\package_transaction.ps1'
$root = Join-Path $env:TEMP ('rvm-package-transaction-test-' + [Guid]::NewGuid().ToString('N'))
foreach ($mode in @('recovery','conflict')) {
    $base = Join-Path $root $mode
    $stage = Join-Path $base 'stage'
    $target = Join-Path $base 'target'
    $backup = Join-Path $base 'backup'
    New-Item -ItemType Directory -Force -Path (Join-Path $stage 'src\newdir'),(Join-Path $target 'src') | Out-Null
    [IO.File]::WriteAllText((Join-Path $stage 'src\replaced.txt'),'package-new')
    [IO.File]::WriteAllText((Join-Path $stage 'src\added.txt'),'package-added')
    [IO.File]::WriteAllText((Join-Path $stage 'src\newdir\nested.txt'),'nested')
    [IO.File]::WriteAllText((Join-Path $target 'src\replaced.txt'),'original')
    [IO.File]::WriteAllText((Join-Path $target 'unrelated.txt'),'unrelated')
    & $helper -Action snapshot -Stage $stage -Target $target -Backup $backup
    $marker = Join-Path $target '.rvm-package-transaction'
    if ([IO.File]::ReadAllText($marker,[Text.Encoding]::UTF8) -cne $backup) { throw 'Recovery marker missing or incorrect.' }
    & $helper -Action deploy -Stage $stage -Target $target -Backup $backup
    if ($mode -eq 'recovery') {
        $manifest = Get-Content -Raw (Join-Path $backup 'manifest.json') | ConvertFrom-Json
        $partial = Join-Path $target ("src\replaced.txt."+$manifest.transactionId+".rvm-new")
        [IO.File]::WriteAllText($partial,'partial staged copy')
    }
    if ($mode -eq 'conflict') { [IO.File]::WriteAllText((Join-Path $target 'src\replaced.txt'),'user-change') }
    $failed = $false
    try { & $helper -Action rollback -Target $target } catch { $failed = $true }
    if ($mode -eq 'recovery') {
        if ($failed -or [IO.File]::ReadAllText((Join-Path $target 'src\replaced.txt')) -cne 'original') { throw 'Interrupted transaction recovery failed.' }
    } else {
        if (-not $failed -or [IO.File]::ReadAllText((Join-Path $target 'src\replaced.txt')) -cne 'user-change') { throw 'Modified user file was not protected.' }
    }
    if (Test-Path -LiteralPath (Join-Path $target 'src\added.txt')) { throw 'Package-created file was not removed.' }
    if (Test-Path -LiteralPath (Join-Path $target 'src\newdir')) { throw 'Package-created directory was not removed.' }
    if ($partial -and (Test-Path -LiteralPath $partial)) { throw 'Partial staged copy was not removed.' }
    if ([IO.File]::ReadAllText((Join-Path $target 'unrelated.txt')) -cne 'unrelated') { throw 'Unrelated file changed.' }
    if (-not (Test-Path -LiteralPath $marker) -or -not (Test-Path -LiteralPath (Join-Path $backup 'manifest.json'))) { throw 'Recovery evidence was removed.' }
    Write-Output "PASS $mode"
}
Write-Output "TEST_DATA_RETAINED=$root"
