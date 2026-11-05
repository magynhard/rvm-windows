param(
    [Parameter(Mandatory = $true)][ValidateSet('snapshot','deploy','rollback')][string]$Action,
    [Parameter(Mandatory = $true)][string]$Target,
    [string]$Backup,
    [string]$Stage
)
$ErrorActionPreference = 'Stop'
$targetPath = [IO.Path]::GetFullPath($Target).TrimEnd('\')
$backupPath = $null
$manifestPath = $null
function Get-Sha256([string]$Path) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-','') }
    finally { $stream.Dispose(); $algorithm.Dispose() }
}
function Assert-NoLinks([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            if (((Get-Item -Force -LiteralPath $current).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing reparse point: $current" }
        }
        $parent = [IO.Path]::GetDirectoryName($current)
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }
}
function Get-TargetPath([string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative)) { throw 'Rooted package path.' }
    $result = [IO.Path]::GetFullPath((Join-Path $targetPath $Relative))
    if (-not $result.StartsWith($targetPath + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Package path escapes installation root.' }
    Assert-NoLinks $result
    return $result
}
Assert-NoLinks $targetPath
if ($Action -eq 'snapshot') {
    if (-not $Backup) { throw 'Backup is required for a snapshot.' }
    $backupPath = [IO.Path]::GetFullPath($Backup).TrimEnd('\')
    $manifestPath = Join-Path $backupPath 'manifest.json'
    Assert-NoLinks $backupPath
    if ($backupPath.StartsWith($targetPath + '\',[StringComparison]::OrdinalIgnoreCase) -or $targetPath.StartsWith($backupPath + '\',[StringComparison]::OrdinalIgnoreCase) -or $backupPath -ieq $targetPath) { throw 'Backup and installation must be separate.' }
    if (-not $Stage) { throw 'Stage is required.' }
    $stagePath = [IO.Path]::GetFullPath($Stage).TrimEnd('\')
    Assert-NoLinks $stagePath
    if ($stagePath -ieq $targetPath -or $stagePath.StartsWith($targetPath + '\',[StringComparison]::OrdinalIgnoreCase) -or $targetPath.StartsWith($stagePath + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Stage and installation must be separate.' }
    if (Test-Path -LiteralPath $manifestPath) { throw 'Snapshot already exists.' }
    New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
    $records = New-Object System.Collections.Generic.List[object]
    $directories = New-Object System.Collections.Generic.List[object]
    foreach ($directory in @(Get-ChildItem -LiteralPath $stagePath -Recurse -Force | Where-Object { $_.PSIsContainer })) {
        Assert-NoLinks $directory.FullName
        $relative = $directory.FullName.Substring($stagePath.Length + 1)
        $destination = Get-TargetPath $relative
        $existed = Test-Path -LiteralPath $destination
        if ($existed -and -not (Test-Path -LiteralPath $destination -PathType Container)) { throw "Package directory collides with a file: $destination" }
        $directories.Add(@{ relative=$relative; existed=$existed })
    }
    foreach ($file in @(Get-ChildItem -LiteralPath $stagePath -Recurse -Force | Where-Object { -not $_.PSIsContainer })) {
        Assert-NoLinks $file.FullName
        $relative = $file.FullName.Substring($stagePath.Length + 1)
        $destination = Get-TargetPath $relative
        $existed = Test-Path -LiteralPath $destination
        if ($existed -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) { throw "Package target is not a file: $destination" }
        $oldHash = $null
        if ($existed) {
            $oldHash = Get-Sha256 $destination
            $old = Join-Path (Join-Path $backupPath 'files') $relative
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $old) | Out-Null
            Copy-Item -LiteralPath $destination -Destination $old
            if ((Get-Sha256 $old) -ne $oldHash) { throw "Backup verification failed: $relative" }
        }
        $records.Add(@{ relative=$relative; existed=$existed; oldHash=$oldHash; newHash=(Get-Sha256 $file.FullName) })
    }
    $manifest = @{ schema=2; transactionId=[Guid]::NewGuid().ToString('N'); target=$targetPath; files=@($records.ToArray()); directories=@($directories.ToArray()) }
    [IO.File]::WriteAllText($manifestPath,($manifest | ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
    # Publish the marker atomically. If the process stops while the snapshot is
    # being prepared, no target package files have been touched yet.
    $marker = Join-Path $targetPath '.rvm-package-transaction'
    $markerTemp = $marker + '.tmp'
    $stream = [IO.File]::Open($markerTemp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($backupPath)
        $stream.Write($bytes,0,$bytes.Length)
        $stream.Flush()
    } finally { $stream.Dispose() }
    try { [IO.File]::Move($markerTemp,$marker) }
    catch { if (Test-Path -LiteralPath $markerTemp) { Remove-Item -LiteralPath $markerTemp }; throw }
    Write-Output "Package snapshot: $backupPath"
} elseif ($Action -eq 'deploy') {
    if (-not $Backup -or -not $Stage) { throw 'Backup and Stage are required for deployment.' }
    $backupPath = [IO.Path]::GetFullPath($Backup).TrimEnd('\')
    $stagePath = [IO.Path]::GetFullPath($Stage).TrimEnd('\')
    $manifestPath = Join-Path $backupPath 'manifest.json'
    Assert-NoLinks $backupPath
    Assert-NoLinks $stagePath
    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.schema -ne 2 -or $manifest.target -ine $targetPath) { throw 'Snapshot target mismatch.' }
    if ($backupPath.StartsWith($targetPath + '\',[StringComparison]::OrdinalIgnoreCase) -or $targetPath.StartsWith($backupPath + '\',[StringComparison]::OrdinalIgnoreCase) -or $backupPath -ieq $targetPath) { throw 'Backup and installation must be separate.' }
    foreach ($record in $manifest.files) {
        $destination = Get-TargetPath ([string]$record.relative)
        $source = [IO.Path]::GetFullPath((Join-Path $stagePath ([string]$record.relative)))
        if (-not $source.StartsWith($stagePath + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Package path escapes staging directory.' }
        Assert-NoLinks $source
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or (Get-Sha256 $source) -ne $record.newHash) { throw "Staged package file failed verification: $($record.relative)" }
        $exists = Test-Path -LiteralPath $destination
        if ($exists -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) { throw "Package target is not a file: $destination" }
        $currentHash = if ($exists) { Get-Sha256 $destination } else { $null }
        $replaceBackup = $destination + "." + $manifest.transactionId + ".rvm-old"
        if ($exists -and $currentHash -eq $record.newHash) {
            if (Test-Path -LiteralPath $replaceBackup) {
                if ((Get-Sha256 $replaceBackup) -ne $record.oldHash) { throw "Unexpected replacement backup: $($record.relative)" }
                Remove-Item -LiteralPath $replaceBackup -Force
            }
            continue
        }
        if ($record.existed -and $exists -and $currentHash -ne $record.oldHash) { throw "Package target changed after snapshot: $($record.relative)" }
        if (-not $record.existed -and $exists) { throw "Package target was created after snapshot: $($record.relative)" }
        if (Test-Path -LiteralPath $replaceBackup) {
            if (-not $record.existed -or (Get-Sha256 $replaceBackup) -ne $record.oldHash) { throw "Unexpected replacement backup: $($record.relative)" }
            Remove-Item -LiteralPath $replaceBackup -Force
        }
        $directory = Split-Path -Parent $destination
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
        $temp = $destination + "." + $manifest.transactionId + ".rvm-new"
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
        try {
            Copy-Item -LiteralPath $source -Destination $temp
            if ((Get-Sha256 $temp) -ne $record.newHash) { throw "Staged copy failed verification: $($record.relative)" }
            if ($exists) {
                [IO.File]::Replace($temp,$destination,$replaceBackup)
                Remove-Item -LiteralPath $replaceBackup -Force
            } else {
                [IO.File]::Move($temp,$destination)
            }
        } catch {
            if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
            throw
        }
    }
    Write-Output "Package files deployed transactionally to $targetPath"
} else {
    if (-not $Backup) {
        $marker = Join-Path $targetPath '.rvm-package-transaction'
        if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { throw 'No interrupted package transaction marker found.' }
        $Backup = [IO.File]::ReadAllText($marker,[Text.Encoding]::UTF8).Trim()
    }
    $backupPath = [IO.Path]::GetFullPath($Backup).TrimEnd('\')
    $manifestPath = Join-Path $backupPath 'manifest.json'
    Assert-NoLinks $backupPath
    if ($backupPath.StartsWith($targetPath + '\',[StringComparison]::OrdinalIgnoreCase) -or $targetPath.StartsWith($backupPath + '\',[StringComparison]::OrdinalIgnoreCase) -or $backupPath -ieq $targetPath) { throw 'Backup and installation must be separate.' }
    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.schema -notin @(1,2) -or $manifest.target -ine $targetPath) { throw 'Snapshot target mismatch.' }
    $conflicts = New-Object System.Collections.Generic.List[string]
    foreach ($record in $manifest.files) {
        $destination = Get-TargetPath ([string]$record.relative)
        $restoreSwap = $null
        if ($manifest.transactionId) {
            $temp = $destination + "." + $manifest.transactionId + ".rvm-new"
            if (Test-Path -LiteralPath $temp -PathType Leaf) { Remove-Item -LiteralPath $temp -Force }
            $replaceBackup = $destination + "." + $manifest.transactionId + ".rvm-old"
            if (Test-Path -LiteralPath $replaceBackup -PathType Leaf) {
                if (-not $record.existed -or (Get-Sha256 $replaceBackup) -ne $record.oldHash) { $conflicts.Add($record.relative); continue }
                Remove-Item -LiteralPath $replaceBackup -Force
            }
            $restoreSwap = $destination + "." + $manifest.transactionId + ".rvm-restore"
        }
        $exists = Test-Path -LiteralPath $destination
        if ($exists -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) { $conflicts.Add($record.relative); continue }
        $hash = if ($exists) { Get-Sha256 $destination } else { $null }
        if ($restoreSwap -and (Test-Path -LiteralPath $restoreSwap -PathType Leaf)) {
            $swapHash = Get-Sha256 $restoreSwap
            if ($hash -eq $record.oldHash -and $swapHash -eq $record.newHash) {
                Remove-Item -LiteralPath $restoreSwap -Force
            } elseif ($swapHash -ne $record.oldHash -and $swapHash -ne $record.newHash) {
                $conflicts.Add($record.relative)
                continue
            }
        }
        if ($exists -and $hash -ne $record.newHash -and $hash -ne $record.oldHash) { $conflicts.Add($record.relative); continue }
        if ($record.existed) {
            $old = Join-Path (Join-Path $backupPath 'files') ([string]$record.relative)
            Assert-NoLinks $old
            if (-not (Test-Path -LiteralPath $old -PathType Leaf) -or (Get-Sha256 $old) -ne $record.oldHash) { throw "Invalid backup: $($record.relative)" }
            if (-not $exists -or $hash -ne $record.oldHash) {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
                $restoreTemp = if ($manifest.transactionId) { $destination + "." + $manifest.transactionId + ".rvm-restore-new" } else { $destination + ".restore" }
                if (Test-Path -LiteralPath $restoreTemp) { Remove-Item -LiteralPath $restoreTemp -Force }
                try {
                    Copy-Item -LiteralPath $old -Destination $restoreTemp
                    if ((Get-Sha256 $restoreTemp) -ne $record.oldHash) { throw "Restored copy failed verification: $($record.relative)" }
                    if ($exists) {
                        [IO.File]::Replace($restoreTemp,$destination,$restoreSwap)
                        Remove-Item -LiteralPath $restoreSwap -Force
                    } else {
                        [IO.File]::Move($restoreTemp,$destination)
                    }
                } catch {
                    if (Test-Path -LiteralPath $restoreTemp) { Remove-Item -LiteralPath $restoreTemp -Force -ErrorAction SilentlyContinue }
                    throw
                }
            }
        } elseif ($exists -and $hash -eq $record.newHash) {
            Remove-Item -LiteralPath $destination
        }
    }
    if ($manifest.schema -eq 2) {
        foreach ($directory in @($manifest.directories | Sort-Object { $_.relative.Length } -Descending)) {
            if ($directory.existed) { continue }
            $path = Get-TargetPath ([string]$directory.relative)
            if (Test-Path -LiteralPath $path -PathType Container) {
                $contents = @(Get-ChildItem -LiteralPath $path -Force)
                if ($contents.Count -eq 0) { Remove-Item -LiteralPath $path }
            }
        }
    }
    if ($conflicts.Count) { throw "Files changed since deployment; retained without overwriting: $($conflicts -join ', '). Backup: $backupPath" }
    Write-Output "Package files restored from $backupPath"
}
