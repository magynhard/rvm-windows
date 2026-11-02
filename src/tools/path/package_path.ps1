param(
    [Parameter(Mandatory = $true)][string]$InstallRoot,
    [string]$WrapperPath,
    [switch]$Remove,
    [switch]$Preview,
    [AllowEmptyString()][string]$CurrentPath = ''
)
$ErrorActionPreference = 'Stop'
if (-not $Remove -and -not $WrapperPath) {
    $rvmHome = if ($env:RVM_HOME) { $env:RVM_HOME } else { [Environment]::GetFolderPath('UserProfile') }
    $configPath = Join-Path $rvmHome '.rvm.json'
    $config = if (Test-Path -LiteralPath $configPath) {
        Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else { $null }
    $data = if ($config.rvm_data_dir) { $config.rvm_data_dir } else { 'C:\ProgramData\rvm' }
    $WrapperPath = Join-Path $data 'wrapper'
}

function Convert-RvmPackagePath([string]$Value) {
    $paths = @($Value.Split(';') | Where-Object { $_ -and $_.TrimEnd('\') -ine $InstallRoot.TrimEnd('\') })
    if (-not $Remove) {
        $paths = @($paths | Where-Object { $_.TrimEnd('\') -ine $WrapperPath.TrimEnd('\') })
        $paths = @($WrapperPath, $InstallRoot) + $paths
    }
    return ($paths -join ';')
}
if ($Preview) {
    Convert-RvmPackagePath $CurrentPath
    exit 0
}

# Read the unexpanded value and write REG_EXPAND_SZ; unlike setx, this neither
# truncates a long PATH nor replaces %VARIABLE% references with expanded values.
$key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
try {
    $raw = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $key.SetValue('Path', (Convert-RvmPackagePath $raw), [Microsoft.Win32.RegistryValueKind]::ExpandString)
} finally {
    $key.Close()
}

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class RvmEnvironmentBroadcast {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg,
        UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);
}
'@
$result = [UIntPtr]::Zero
[void][RvmEnvironmentBroadcast]::SendMessageTimeout([IntPtr]0xffff, 0x1a,
    [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
