param(
    [string]$InstallRoot = $env:RVM_NPM_INSTALL_ROOT,
    [switch]$Preview,
    [switch]$Manual
)
$ErrorActionPreference = 'Stop'
if (-not $Manual -and $env:npm_config_global -ne 'true') {
    throw 'RVM is a per-user Windows application. Use npm install -g rvm-windows, or run install.ps1 -Manual.'
}
if (-not $InstallRoot) {
    $existing = Get-ItemProperty -LiteralPath 'HKCU:\Software\rvm-windows.cr' -ErrorAction SilentlyContinue
    $InstallRoot = if ($existing.InstallDir) { $existing.InstallDir } else { Join-Path $env:LOCALAPPDATA 'Programs/rvm-windows' }
}
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot)
$setup = Join-Path $PSScriptRoot 'rvm-windows-setup.exe'
$prefix = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$expectedPackage = Join-Path $prefix 'node_modules/rvm-windows'
if ([IO.Path]::GetFullPath($expectedPackage).TrimEnd('\') -ine $PSScriptRoot.TrimEnd('\')) {
    throw 'The npm bridge must be installed as <prefix>/node_modules/rvm-windows.'
}
if ($InstallRoot -match '[\r\n"]' -or $InstallRoot.StartsWith($PSScriptRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or $PSScriptRoot.StartsWith($InstallRoot.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or $InstallRoot -ieq $PSScriptRoot) {
    throw 'The native installation must be outside the npm package.'
}
if ($Preview) {
    @{ installRoot = $InstallRoot; setup = $setup; prefix = $prefix; arguments = "/S /NPMBRIDGE /D=$InstallRoot" } | ConvertTo-Json -Compress
    exit 0
}
$native = Join-Path $InstallRoot 'bin/rvm.exe'
$packageVersion = [version](Get-Content -LiteralPath (Join-Path $PSScriptRoot 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json).version
$keepNewer = $false
if (Test-Path -LiteralPath $native -PathType Leaf) {
    try {
        $output = @(& $native --internal-version 2>$null)
        $installedVersion = $null
        if ($LASTEXITCODE -eq 0 -and $output.Count -eq 1 -and [version]::TryParse([string]$output[0], [ref]$installedVersion)) {
            $keepNewer = $installedVersion -gt $packageVersion
        }
    } catch { $keepNewer = $false }
}
if (-not $keepNewer) {
    if (-not (Test-Path -LiteralPath $setup -PathType Leaf)) { throw 'Bundled native setup is missing. Reinstall the npm package.' }
    $process = Start-Process -FilePath $setup -ArgumentList "/S /NPMBRIDGE /D=$InstallRoot" -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Native RVM setup failed (exit $($process.ExitCode))." }
} else {
    Write-Output 'Keeping the newer native RVM installation; updating only the npm bridge.'
}
if (-not (Test-Path -LiteralPath $native -PathType Leaf)) { throw 'Native RVM executable is missing after setup.' }
$utf8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'install-root.txt'), $InstallRoot + "`r`n", $utf8)

# npm's CMD shim uses SETLOCAL. Establish the session before that scope begins;
# PowerShell must likewise set the parent process environment before calling CMD.
# Modify only shims that demonstrably target this package's own bridge.
$helpers = Join-Path $PSScriptRoot 'src/tools/current'
$lines = @{
    '.cmd' = 'call "' + (Join-Path $helpers 'cmd_rvm_prepend.bat') + '"'
    '.ps1' = "& '" + (Join-Path $helpers 'ps_rvm_prepend.ps1').Replace("'", "''") + "'"
}
foreach ($extension in @('.cmd', '.ps1')) {
    $shim = Join-Path $prefix ('rvm' + $extension)
    if (-not (Test-Path -LiteralPath $shim -PathType Leaf)) { throw "Expected npm launcher is missing: $shim" }
    $text = [IO.File]::ReadAllText($shim)
    if ($text -notmatch 'node_modules[\\/]rvm-windows[\\/]rvm\.cmd') { throw "Refusing to modify an unrelated launcher: $shim" }
    $line = $lines[$extension]
    $parts = @($text -split '\r?\n')
    if ($parts -notcontains $line) {
        $text = (@($parts[0], $line) + @($parts | Select-Object -Skip 1)) -join "`r`n"
        # PS 5.1 requires a BOM for non-ASCII helper paths; CMD must not have one.
        $encoding = New-Object Text.UTF8Encoding($extension -eq '.ps1')
        [IO.File]::WriteAllText($shim, $text, $encoding)
    }
}
Write-Output 'Native RVM installed. Open a new CMD or PowerShell terminal, then run rvm version.'
