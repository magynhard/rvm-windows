# Porting contract

Source: `magynhard/rvm-windows` at `ecf0758c6027977c89f4306e1933b871ebda4c41`.

* Preserve source classes and task/wrapper file boundaries; use Crystal snake_case.
* One native Windows x64 executable, including internal wrapper subcommands.
* Preserve ~/.rvm.json (including unknown JSON keys), ~/.rvm/sessions,
  RVM_SESSION, C:/ProgramData/rvm and existing installed Ruby environments.
* Preserve batch environment save/restore, command forwarding and exit status.
* No separate runtime dependency. Updates use GitHub Releases and NSIS.
* Specs must isolate configuration, sessions, downloads and wrappers. Never run
  installers, kill MSYS processes, change the registry or user PATH in tests.
* Commit compilable milestones. Native installation/update validation is separate
  from automated tests and must not touch an existing installation implicitly.

## Milestones

1. Native executable and Crystal project skeleton.
2. Configuration, version resolution and all five wrapper entrypoints.
3. CLI tasks and equivalent tests, plus isolated integration coverage.
4. Distribution, NSIS setup, CI and documented validation/limitations.

## File mapping

`src/cli/cli.cr`, `_tools.cr`, `_wrapper.cr`, the task files in `src/cli/tasks`
and all five `src/wrapper/wrapper_*.cr` retain the established class boundaries.
The executable entrypoint is `src/rvm-windows.cr`; `src/test_cli_loader.cr`
provides an interactive task console. Release tooling is in `scripts/release.cr`.
Tests use Crystal `*_spec.cr` files under the same logical directories, with
checked-in reference data for compatibility checks. Project metadata lives in
`shard.yml`; no external shards are needed.
Existing image assets and LICENSE are retained. Existing batch/PowerShell
helpers are copied verbatim; only the wrapper template's runtime calls change.

## Preserved original quirks

* `k` dispatches to `kick`, not the documented `kit` shortcut.
* `s` dispatches to `scan`, not the documented `system` shortcut.
* `ri` dispatches to `reinstall`; the help table's `r` does not.
* `default` selects the configured default; `config default <version>` sets it.
* `upgrades` is not a standalone task; use `list upgrades` / `lu`.
* The scan's shadowed `where ruby` output is discarded in the original. The port
  preserves its actual directory scan rather than silently broadening it.
* Missing exact-version commands can fall back to the current session Ruby.
* Duplicate archive builds remain in `list all`, as in the original.
* `use --default 3.2` sets the default; the original's argument quirk means
  `use --default ruby-3.2` only switches. `use ruby-3.2 --default` sets it.

## Necessary platform adaptations and explicit differences

* Owned root launchers call private `bin/rvm.exe` rather than patching arbitrary
  launchers found through `where rvm`. Session prepends remain unchanged.
* Output uses simple tables rather than an external table renderer.
  Fields and command behavior are preserved; layout is not byte-identical.
* Neutral primary highlights use Windows blue instead of the original green.
  Green is retained for positive statuses; errors remain red and warnings yellow.
* Network errors fail explicitly instead of leaving an unresolved Promise.
  Incomplete downloads never become usable cache entries.
* The original legacy `init` PATH operation remains; NSIS uses a separate helper
  that preserves long/unexpanded PATH values. Installer hooks do not scan or kill
  processes, and uninstallation removes only wrappers owned by this executable.
* `get` uses GitHub Release setup assets. Self-update and actual
  installation still require disposable-machine acceptance testing.
* Release preparation commits/tags locally, but does not push or publish assets.
  Tag CI creates a draft GitHub release, never an automatically published release.
