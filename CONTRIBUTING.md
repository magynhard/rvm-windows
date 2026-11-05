# Contributing to rvm-windows

Bug reports and pull requests are welcome at
[magynhard/rvm-windows](https://github.com/magynhard/rvm-windows).
For installation and everyday usage, see [README.md](README.md).

## Compatibility target

This is the native Crystal implementation of rvm-windows. The previous JavaScript
implementation is preserved on the [legacy-js branch](https://github.com/magynhard/rvm-windows/tree/legacy-js)
and in the existing 1.0.x tags. Both implementations' Git histories are retained.
The initial compatibility target is the original 1.0.8 command behavior,
RubyInstaller x64 environments, `~/.rvm.json`, `~/.rvm/sessions`, `RVM_SESSION`,
and `C:\ProgramData\rvm`. Unknown configuration fields must survive writes.

Batch files still perform environment save/restore, argument forwarding and
exit-code propagation; the five wrapper operations are internal commands
of one executable. Source files and classes follow the original tree, with
idiomatic `snake_case` methods and Crystal `*_spec.cr` naming.

Do not silently change established command behavior; document and discuss
compatibility changes separately.

## Development setup and build

Use Windows 10+ x64, Crystal 1.20.2+ and the Visual Studio C++ build tools.
There are no third-party shards or external reference-test dependencies.

```powershell
crystal run scripts/build.cr
.\rvm.cmd version
crystal spec
```

The build creates `bin/rvm.exe` (release, statically linked) and CMD/PowerShell
launchers in the project root. Keep `src/templates` and `src/tools` alongside
it. End users need neither a compiler nor separate runtime DLLs.

`shards build` produces a faster, dynamically linked developer build instead.

### Installer artwork

`src/assets/img/rvm-windows-icon.svg` is the editable square icon source. With
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
Compatibility specs compare ANSI-colored output against checked-in reference
data, including Windows-blue primary highlights and semantic status colors.

### Compatibility and optional live checks

```powershell
$env:RVM_LIVE_TESTS = '1'
crystal spec
```

The live check retrieves the RubyInstaller archive. Offline compatibility tests
use fixed reference data for version resolution, list output, wrapper selection,
missing-parameter explanations and all help task descriptions. Preserve complete
explanations and examples; only adapt content where the distribution or a
deliberately changed behavior requires it.

Remove `RVM_LIVE_TESTS` to return to the default offline suite.

### Packaged executable smoke test

After building a package:

```powershell
$env:RVM_PACKAGE_ROOT = (Resolve-Path dist/rvm-windows-1.1.1-windows-x64).Path
crystal spec spec/package_spec.cr
```

This checks the staged executable with only Windows system directories on PATH,
without a compiler or third-party runtime DLLs available through PATH.
Adjust the version in the directory name for the package being tested.

### Interactive task console

```powershell
crystal run src/test_cli_loader.cr
```

The console accepts CLI tasks, not arbitrary source expressions; use a scratch
`.cr` file to call classes directly.

## Packaging and installer development

```powershell
# Optional, to also build setup:
$env:MAKENSIS = 'C:\Program Files (x86)\NSIS\makensis.exe'
crystal run scripts/package.cr
```

For version 1.1.1-develop.1, output is
`dist/rvm-windows-1.1.1-develop.1-windows-x64.zip` and, with NSIS installed,
`dist/rvm-windows-1.1.1-develop.1-windows-x64-setup.exe` plus the npm bridge
`dist/rvm-windows-1.1.1-develop.1.tgz`. Building the latter also requires npm on PATH;
`npm pack` never publishes anything.

The per-user NSIS setup supports installing over the same application directory.
It regenerates shared Ruby wrappers for the new executable and updates the user
PATH without truncating it. Existing JSON configuration, sessions, Ruby installs
and download caches must be retained. Close running RVM commands before upgrading.

Installing takes over the shared wrapper directory from any previous installation.
Do not operate multiple installations concurrently while changing configuration
or wrappers. When switching installations, restore the desired PATH priority
and run its `rvm fix` to regenerate wrappers. Uninstalling removes only
its own wrappers and package files, not installed Rubies or user configuration.

Use a disposable Windows VM for installer, upgrade and uninstall acceptance tests.

To run the isolated NSIS failure-path fixtures on Windows (they retain their
temporary test directories and never run the production setup):

```powershell
./scripts/test-installer-failures.ps1 -Makensis 'C:\Program Files (x86)\NSIS\makensis.exe'
```

These fixtures test preflight, migration preparation, deployment failure and a
locked executable. They do not replace real installer/update acceptance or prove
that all package files roll back after an interruption.

## Releases and self-update

`rvm get` uses GitHub Releases in `magynhard/rvm-windows`: it fetches the
latest published `*-setup.exe` and schedules silent installation after the
current process exits. This requires published setup assets.
Validate the full wait/download/replace/reinitialize flow on a disposable machine.

Add and commit a dated changelog entry, then run:

```powershell
crystal run scripts/release.cr -- 1.1.1-develop.2
```

This tests, bumps the manifest, commits and tags **locally only**. After review,
push explicitly. The [Windows workflow](.github/workflows/windows.yml) builds
ZIP/setup assets and creates a **draft** GitHub Release for version tags.
Publication remains a maintainer action.

### npm distribution and legacy migration

`npm/` is a minimal installer bridge with no application dependencies. Its version
must match `shard.yml`; release tooling bumps both. The packaged bridge bundles
the exact setup built above, not an executable downloaded at install time.
`postinstall` invokes setup, records its separate install root, and prepends the
session helper to this package's own npm CMD/PowerShell shims. Keeping those
helpers at their established paths also supports the old updater's finalisation.

Run integration checks explicitly (requires npm, uses temporary prefixes/caches):

```powershell
$env:RVM_NPM_TESTS = '1'
crystal spec spec/npm_bridge_spec.cr
```

These tests use a harmless compiled setup stand-in, never the real installer.
They cover a legacy npm update and its finalisation, shell sessions, skipped
scripts, installer failure, repeated installation, downgrade prevention and
targeted uninstall. Normal tests cover migration plans and rollback without
running npm. Real installer/registry acceptance still needs a disposable VM.

`LegacyInstallationMigration` in `src/migration/legacy_installation_migration.cr`
is the temporary compatibility boundary. Setup calls prepare/commit/rollback;
cleanup runs in a separate worker after active npm/legacy processes finish.
Before replacing shared wrappers, setup checks for active managed Ruby tools
and asks the user to close them rather than killing processes.
Only verified pre-1.1.0 packages from PATH, the configured npm prefix or the
standard per-user prefix are eligible. Current bridges, links/junctions, changed
manifests and packages containing protected paths are never uninstalled.
Cleanup uses npm with an explicit global prefix and disabled lifecycle scripts.
Backups/logs live in `~/.rvm/migration`; explicit `rvm init` retries pending jobs.
If setup was interrupted before commit, run the installed `bin/rvm.exe
--internal-migration rollback` with `RVM_ROOT` set to that installation before
retrying setup. This restores owned wrappers, not arbitrary configuration edits.

For an npm release, review the `.tgz` and test with a temporary prefix first.
Publish explicitly using `npm publish ./dist/rvm-windows-1.1.1-develop.1.tgz --access public --tag develop`
with an authorised npm account. Neither packaging nor tag CI publishes to npm.
Do not replace existing tags or published package versions; publish a new version.

Develop packages use prerelease versions and `publishConfig.tag` is `develop` as
a safeguard. Verify npm's `latest` tag before and after publishing: it must remain
unchanged. Testers explicitly install `rvm-windows@develop`. GitHub test releases
must be marked as prereleases; do not promote either channel to stable yet.
Code signing is a follow-up after manual installer and npm acceptance.

### Windows publisher identity and signing

Setup includes publisher/version metadata, but metadata does not authenticate
the publisher. Public releases need Authenticode signatures from a trusted
code-signing provider. Sign `bin/rvm.exe` before packaging, sign the uninstaller
during NSIS compilation (`!uninstfinalize`), then sign the final setup; include
SHA-256 digests and an RFC 3161 timestamp, and verify signatures before upload.
Keep the signing identity consistent across releases and signing credentials
outside the repository. A trusted signature identifies the publisher but does
not guarantee immediate SmartScreen reputation or eliminate every warning.

Options include [SignPath Foundation](https://signpath.org/) for qualifying
open-source projects, a commercial code-signing certificate, or
[Azure Artifact Signing](https://learn.microsoft.com/en-us/azure/artifact-signing/)
where identity/region eligibility permits. Self-signed certificates are suitable
only for testing or environments with explicitly managed certificate trust.

## License and third-party notices

MIT, retaining the original author and license. Static binaries also contain
the Crystal runtime and its dependencies. Before publishing, audit and include
all required third-party licenses/notices for the exact toolchain; the project's
MIT license alone is insufficient.

## Community

This project is intended to be a safe, welcoming space for collaboration.
Contributors are expected to adhere to the
[Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.
