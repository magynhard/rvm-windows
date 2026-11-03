# Contributing to rvm-windows.cr

Bug reports and pull requests are welcome at
[magynhard/rvm-windows.cr](https://github.com/magynhard/rvm-windows.cr).
For installation and everyday usage, see [README.md](README.md).

## Compatibility target

This is the native Crystal port of [rvm-windows](https://github.com/magynhard/rvm-windows).
The initial compatibility target is the original 1.0.8 command behavior,
RubyInstaller x64 environments, `~/.rvm.json`, `~/.rvm/sessions`, `RVM_SESSION`,
and `C:\ProgramData\rvm`. Unknown configuration fields must survive writes.

Batch files still perform environment save/restore, argument forwarding and
exit-code propagation; the five former JavaScript scripts are internal commands
of one executable. Source files and classes follow the original tree, with
idiomatic `snake_case` methods and Crystal `*_spec.cr` naming.

See [porting notes](doc/PORTING.md) for the file mapping, original dispatch quirks
and necessary platform adaptations. Do not silently fix behavior differences
while porting; document and discuss them separately.

## Development setup and build

Use Windows 10+ x64, Crystal 1.20.2+ and the Visual Studio C++ build tools.
There are no third-party shards. Node.js is only needed for the optional
differential tests against the original checkout.

```powershell
crystal run scripts/build.cr
.\rvm.cmd version
crystal spec
```

The build creates `bin/rvm.exe` (release, statically linked) and CMD/PowerShell
launchers in the project root. Keep `src/templates` and `src/tools` alongside
it. End users need neither Crystal nor Node nor separate runtime DLLs.

`shards build` produces a faster, dynamically linked developer build instead.

### Installer artwork

`doc/img/rvm-windows-icon.svg` is the editable square icon source. With
ImageMagick on PATH, run `./scripts/generate-icon.ps1` to regenerate its PNG
preview and the multi-resolution `rvm-windows.ico` (16–256 pixels). Generated
assets are committed; normal builds do not need ImageMagick. NSIS uses this
icon for setup, uninstall and the installed-apps entry.

**Use the root launchers, not `bin/rvm.exe` directly**, for session-sensitive
commands: only the parent CMD/PowerShell process can establish the persistent
`RVM_SESSION`. Put the package root on PATH, not its private `bin` directory.

> [!WARNING]
> Development commands use your existing RVM configuration unless you override
> its paths. Explicit `init`, `fix`, install, uninstall and kit commands modify
> the configured installation. Use an isolated home or a disposable VM when
> testing those operations.

## Tests and formatting

```powershell
crystal tool format --check src spec scripts
crystal spec
```

Normal tests are offline and use temporary homes, configuration, sessions, fake
commands and local HTTP/proxy servers. They never execute Ruby installers,
mutate the registry/user PATH, install gems or kill MSYS processes. The batch
integration specs compile their own executable fixtures.

Use `Fixtures.with_home` for configuration/session tests. `RVM_HOME` and
`RVM_ROOT` override paths for isolation; omit them for normal,
original-compatible behavior. For tasks that shell out, prefer pure command
builders or compiled fixtures over interacting with a real Ruby installation.

### CLI colors

`RvmCliColor` uses Crystal's standard-library `Colorize` with per-output-stream
terminal detection. Crystal enables Windows virtual-terminal processing for
console stdout/stderr. Use `primary` (light blue, shared with the Windows logo)
for neutral highlights such as commands, version names, paths and options. Keep
green for positive status (enabled, installed archive releases, up-to-date), red
for errors and yellow for warnings. The logo version is white. Do not add escape
sequences to configuration/session values or internal protocols.

`NO_COLOR` (non-empty) disables colors, `FORCE_COLOR=1` forces them even in pipes,
and `FORCE_COLOR=0` disables them. `NO_COLOR` takes precedence. By default, pipes,
files and `TERM=dumb` output stay plain. Wrapper/setup protocols remain plain
even with `FORCE_COLOR=1`.

Color specs exercise simulated terminal streams, forced/disabled colors in the
compiled executable, plain configuration/session writes, and protocol safety.
The optional reference suite compares actual ANSI-colored output to Chalk,
accounting for the intentional green-to-blue primary-color replacement.

### Optional live and differential checks

```powershell
$env:RVM_LIVE_TESTS = '1'
$env:RVM_JS_REFERENCE = '..\rvm-windows'
crystal spec
```

The live check retrieves the RubyInstaller archive. The differential check
requires Node.js and the original repository with its dependencies installed;
it compares the original version resolution, list output, wrapper selection,
missing-parameter explanations and all help task descriptions with the Crystal
implementation. Preserve complete explanations and examples; only adapt content
where the Crystal distribution or a deliberately changed behavior requires it.

Remove these environment variables to return to the default offline suite.

### Packaged executable smoke test

After building a package:

```powershell
$env:RVM_PACKAGE_ROOT = (Resolve-Path dist/rvm-windows-1.1.0-windows-x64).Path
crystal spec spec/package_spec.cr
```

This checks the staged executable with only Windows system directories on PATH,
without Node, Crystal or third-party runtime DLLs available through PATH.
Adjust the version in the directory name for the package being tested.

### Interactive task console

```powershell
crystal run src/test_cli_loader.cr
```

Crystal does not have JavaScript's runtime eval. The console accepts CLI tasks;
use a scratch `.cr` file to call classes directly.

## Packaging and installer development

```powershell
# Optional, to also build setup:
$env:MAKENSIS = 'C:\Program Files (x86)\NSIS\makensis.exe'
crystal run scripts/package.cr
```

For version 1.1.0, output is
`dist/rvm-windows-1.1.0-windows-x64.zip` and, with NSIS installed,
`dist/rvm-windows-1.1.0-windows-x64-setup.exe`.

The per-user NSIS setup supports installing over the same application directory.
It regenerates shared Ruby wrappers for the new executable and updates the user
PATH without truncating it. Existing JSON configuration, sessions, Ruby installs
and download caches must be retained. Close running RVM commands before upgrading.

Installing takes over the shared wrapper directory from the Node version.
Do not operate both implementations concurrently while changing configuration
or wrappers. To return to the Node implementation, restore its PATH priority
and run its `rvm fix` to regenerate wrappers. Uninstalling this port removes only
its own wrappers and package files, not installed Rubies or user configuration.

Use a disposable Windows VM for installer, upgrade and uninstall acceptance tests.
See [validation status and release checklist](doc/VALIDATION.md) for automated
coverage and outstanding manual acceptance checks before a public release.

## Releases and self-update

`rvm get` uses GitHub Releases in `magynhard/rvm-windows.cr`: it fetches the
latest published `*-setup.exe` and schedules silent installation after the
current process exits. This requires published assets; there is no npm fallback.
Validate the full wait/download/replace/reinitialize flow on a disposable machine.

Add and commit a dated changelog entry, then run:

```powershell
crystal run scripts/release.cr -- 1.1.1
```

This tests, bumps the manifest, commits and tags **locally only**. After review,
push explicitly. The [Windows workflow](.github/workflows/windows.yml) builds
ZIP/setup assets and creates a **draft** GitHub Release for version tags.
Publication remains a maintainer action.

## License and third-party notices

MIT, retaining the original author and license. Static binaries also contain
the Crystal runtime and its dependencies. Before publishing, audit and include
all required third-party licenses/notices for the exact toolchain; the project's
MIT license alone is insufficient. See the [release checklist](doc/VALIDATION.md).

## Community

This project is intended to be a safe, welcoming space for collaboration.
Contributors are expected to adhere to the
[Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.
