& "$PSScriptRoot\src\tools\current\ps_rvm_prepend.ps1"
$waitForUpdate = $args.Count -gt 0 -and $args[0] -ieq 'get' -and $env:RVM_SESSION
$updateStatus = if ($waitForUpdate) { Join-Path $PSScriptRoot ".rvm-update-$env:RVM_SESSION.status" } else { $null }
$oldUpdateLauncher = $env:RVM_UPDATE_LAUNCHER
if ($updateStatus -and (Test-Path -LiteralPath $updateStatus)) {
    if ([IO.File]::ReadAllText($updateStatus).Trim() -ne 'pending') { Remove-Item -LiteralPath $updateStatus -Force }
}
if ($updateStatus) { $env:RVM_UPDATE_LAUNCHER = '1' }
& "$PSScriptRoot\bin\rvm.exe" @args
$exitCode = $LASTEXITCODE
if ($updateStatus) { $env:RVM_UPDATE_LAUNCHER = $oldUpdateLauncher }
if ($updateStatus -and (Test-Path -LiteralPath $updateStatus)) {
    do {
        Start-Sleep -Seconds 1
        $result = if (Test-Path -LiteralPath $updateStatus) { [IO.File]::ReadAllText($updateStatus).Trim() } else { '' }
    } while ($result -notin @('0','1'))
    Remove-Item -LiteralPath $updateStatus -Force -ErrorAction SilentlyContinue
    if ($result -eq '0') {
        Write-Output 'RVM update completed successfully.'
    } else {
        [Console]::Error.WriteLine('RVM setup failed. Check update-*.ps1.log in your RVM data downloads directory.')
        $exitCode = 1
    }
}
exit $exitCode
