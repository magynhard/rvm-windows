# check if env RVM_CURRENT_SESSION is set already
if ($env:RVM_SESSION) {
    # do nothing
} else {
    # generate unique id for current terminal
    $random = Get-Random -Minimum 1000 -Maximum 9999
    $time = (Get-Date).Second
    $newUniqueId = $random * 1000 + $time
    [Environment]::SetEnvironmentVariable("RVM_SESSION", $newUniqueId, "Process")
}