# rvm-windows.cr

Native Crystal port of [rvm-windows](https://github.com/magynhard/rvm-windows),
the Ruby Version Manager for Windows. No Node.js runtime is required.

**Compatibility target:** the original 1.0.8 command behavior, RubyInstaller x64
environments, `~/.rvm.json`, `~/.rvm/sessions`, `RVM_SESSION`, and
`C:\ProgramData\rvm`. Unknown configuration fields survive writes. Batch files
still perform environment save/restore, argument forwarding, and exit-code
propagation; the five former JavaScript scripts are internal commands of one EXE.

## Build

Windows 10+ x64, Crystal 1.20.2+ and the Visual Studio C++ build tools are needed
for development. There are no third-party shards.

```powershell
crystal run scripts/build.cr
.\rvm.cmd version
crystal spec
```

The build creates `bin/rvm.exe` (release, statically linked) and CMD/PowerShell
launchers in the project root. Keep the `src/templates` and `src/tools` assets
alongside it. End users need neither Crystal nor Node nor separate runtime DLLs.
`shards build` remains available for a faster, dynamically linked developer build.

**Use the launchers, not `bin/rvm.exe` directly**, for session-sensitive commands:
only the parent CMD/PowerShell process can establish the persistent `RVM_SESSION`.
Put the package root on PATH, not its private `bin` directory.

## Package / install

```powershell
# Optional, to also build setup:
$env:MAKENSIS = 'C:\Program Files (x86)\NSIS\makensis.exe'
crystal run scripts/package.cr
```

Output: `dist/rvm-windows-1.0.8-windows-x64.zip` and, with NSIS installed,
`dist/rvm-windows-1.0.8-windows-x64-setup.exe`.

The per-user NSIS setup supports installing over the same application directory.
It regenerates shared Ruby wrappers for the new executable and updates the user
PATH without truncating it. Existing JSON configuration, sessions, Ruby installs
and download caches are retained. Close running RVM commands before upgrading.

**Installing takes over the shared wrapper directory from the Node version.**
Do not operate both implementations concurrently while changing configuration or
wrappers. To return to the Node implementation, restore its PATH priority and run
its `rvm fix` to regenerate wrappers. Uninstalling this port removes only its own
wrappers and package files, not installed Rubies or user configuration.

For a ZIP installation, extract the entire package, add its root to PATH, and run
`rvm init` in a new terminal. As with the original, explicit `init`, `fix`, install,
uninstall and kit commands intentionally modify the configured installation.

## Commands

```powershell
rvm help
rvm list
rvm list known
rvm install 3.3
rvm use --default 3.3
rvm current
rvm config proxy http://proxy:12345
```

Full commands, shortcuts and per-command classes mirror the original. See
[porting notes](doc/PORTING.md) for original dispatch quirks.

`rvm get` is prepared for GitHub Releases in `magynhard/rvm-windows.cr`: it fetches
the latest published `*-setup.exe` and schedules silent installation after the
current process exits. This requires published assets; there is no npm fallback.

## Tests and development

```powershell
crystal tool format --check src spec scripts
crystal spec
# Optional live archive checks and differential tests against the original:
$env:RVM_LIVE_TESTS = '1'
$env:RVM_JS_REFERENCE = '..\rvm-windows'
crystal spec
# Optional staged static-package smoke test:
$env:RVM_PACKAGE_ROOT = (Resolve-Path dist/rvm-windows-1.0.8-windows-x64).Path
crystal spec spec/package_spec.cr
```

Normal tests are offline and use temporary homes, config, sessions, fake commands
and local HTTP/proxy servers. They never execute Ruby installers, mutate the
registry/user PATH, install gems or kill MSYS processes. The batch integration
specs compile their own executable fixtures. `RVM_HOME` and `RVM_ROOT` override
paths for isolation; omit them for normal, original-compatible behavior.

`crystal run src/test_cli_loader.cr` provides an interactive task console. Crystal
does not have JavaScript's runtime eval; use a scratch `.cr` file to call classes
directly. Source files and classes otherwise follow the original tree, with
idiomatic `snake_case` methods and Crystal `*_spec.cr` naming.

## Releases

Add and commit a dated changelog entry, then run:

```powershell
crystal run scripts/release.cr -- 1.0.9
```

This tests, bumps the manifest, commits and tags **locally only**. After review,
push explicitly. The Windows workflow builds ZIP/setup assets and creates a
**draft** GitHub Release for version tags. Publication remains a maintainer action.

See [validation status](doc/VALIDATION.md) for tests performed and outstanding
manual acceptance checks before a public release.

## License

MIT, retaining the original author and license. Static binaries also contain the
Crystal runtime and its dependencies; distribution must include their required
third-party notices (see the release checklist).
