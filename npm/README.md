# rvm-windows

Ruby Version Manager for Windows, implemented in Crystal. This package installs
the native per-user Windows application; it is not a second CLI implementation.

```powershell
npm install -g rvm-windows@latest
```

Open a new CMD or PowerShell terminal, then run `rvm version`. Update using
`npm update -g rvm-windows`, `rvm get`, or the newer native setup.

The native setup is bundled, so installation does not download an executable
from a separate server. Existing `.rvm.json`, sessions and Ruby installations
are retained. No compiler is required.

Install-time scripts must be permitted. If your npm version supports script
approval, approve this package with `--allow-scripts=rvm-windows`. Do not disable
script protections globally. If scripts were skipped, run the installed package's
`install.ps1` with PowerShell and `-Manual`, or use the setup from GitHub Releases.
`RVM_NPM_INSTALL_ROOT` optionally selects a custom native installation directory.

The small npm bridge stays installed to support future npm updates. Removing it
with npm does not uninstall the native application; use Windows Installed Apps
to remove the latter. Removing RVM does not remove installed Rubies or user config.

Documentation and releases: https://github.com/magynhard/rvm-windows.cr
