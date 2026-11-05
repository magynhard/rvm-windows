# Unreleased
- Preserve Unicode paths when `rvm get` launches Windows PowerShell 5.1 and record the silent setup result in a log.

# 1.1.2 - 2026-11-05
- Preflight the staged executable and migration before replacing installed package files.
- Deploy package files with per-file staging, SHA-256 verification and atomic replacement; restore backups on failure and recover interrupted deployments on setup retry.
- Preserve concurrent user file changes by refusing conflicting rollback overwrites; retain a recovery marker and backup for manual inspection.
- Keep npm CMD helper launchers safe under non-UTF-8 codepages and Unicode Node installation paths, including legacy `rvm get` finalisation.

# 1.1.1 - 2026-11-04
- Publish the first stable native GitHub release; the npm native bridge remains available separately via the develop tag.
- Show the product's full name instead of its implementation language in Windows Installed Apps.

# 1.1.1-develop.1 - 2026-11-04
- Make `rvm get` explain an empty stable GitHub release channel without failing; retain errors for failed downloads and other HTTP responses.
- Use the native Nokogiri gem for UCRT Ruby in `rvm kit`, avoiding its bundled libiconv source-build failure in Ruby paths containing spaces; retain legacy pins.
- Consolidate the native implementation into the original rvm-windows repository, preserving both Git histories and the JavaScript implementation on legacy-js.
- Point updates, npm metadata and documentation to magynhard/rvm-windows; keep existing JavaScript tags and releases unchanged.
- Prepare opt-in npm testing under the develop tag; leave latest unchanged.
- Support prerelease versions in self-update, the npm bridge, release tooling and Windows installer metadata.
- Mark GitHub prerelease drafts explicitly in CI.
- Correct CLI help shortcuts, preserve long PATH values during init and keep sessions across boot-time rounding boundaries.
- Fix Crystal formatting required by CI.
- Add an npm installation bridge for native setup and updates.
- Isolate legacy installation discovery, wrapper rollback and deferred package cleanup in a removable migration class.
- Preserve configuration, sessions, Ruby installations and caches during migration.

# 1.1.0 - 2026-11-03
Experimental standalone Crystal port; not an official native release in the original repository. Official stable native releases start with 1.1.1.

- Implement CLI tasks, wrapper entrypoints and tests in Crystal.
- Build one statically linked native Windows executable without a separate runtime.
- Preserve shared configuration, session format, Ruby environments and batch methodology.
- Restore the original CLI colors for the logo, help, versions, paths, warnings and errors; keep wrapper protocols uncolored.
- Use Windows blue for primary CLI highlights, preserve semantic status colors, and align the white logo version.
- Explicitly invoke CMD for Windows shell commands, fixing `rvm info` (`ver`) and command chaining.
- Preserve full original missing-parameter explanations and help descriptions, including both upgrade forms and their example.
- Generate CRLF batch wrappers to prevent truncated commands (`ET` instead of `SET`) with UTF-8 installation paths in CMD and PowerShell.
- Prepare ZIP/NSIS distribution, GitHub Releases updates and Windows CI.
- Add a custom ruby/Windows icon for setup, uninstall and the installed-apps entry.
- Fix Unicode license text in setup and add publisher/version metadata.

---

The entries below document the previous Node.js version. Starting with 1.1.0,
rvm-windows has been reimplemented in Crystal.

# 1.0.8 - 2026-11-02
- Fix [#14](https://github.com/magynhard/rvm-windows/issues/14), allow initialization when the installation path contains spaces, thanks to [sk-ys](https://github.com/sk-ys)

# 1.0.7 - 2026-07-23
- Fix [#12](https://github.com/magynhard/rvm-windows/issues/12), preserve wrapped command exit codes after environment cleanup and post-command processing

# 1.0.5 - 2026-06-14
- Fix installing multiple patch versions of the same minor Ruby version (e.g. 3.3.8 and 3.3.9) side by side
  - RubyInstaller's InnoSetup uses an AppId based on major.minor only, causing it to silently uninstall an existing same-minor installation before installing the new one. Removed the registry key before running the installer to prevent the auto-uninstall.
- Fix missing closing quote on the `/tasks` flag in the installer command
- See pull request [#10](https://github.com/magynhard/rvm-windows/pull/10)
- Added a release script to automate version bumping, tagging, and publishing

# 1.0.4 - 2025-11-10
- Add CLI support to set rvm data directory, via `rvm config set data <path>`, thanks to [paul-c-hartman](https://github.com/paul-c-hartman)
- See pull request [#8](https://github.com/magynhard/rvm-windows/pull/8)

# 1.0.2 - 2025-09-07
- Fix [#3](https://github.com/magynhard/rvm-windows/issues/3), honor `MSYS2_PATH` env variable, when installing new rubies.
  -  This allows to use a central MSYS2 installation, instead of installing a new one for each ruby version.
- Added an interactive console to test the `rvm-windows` environment
- Updated dependencies
- Fix [#6](https://github.com/magynhard/rvm-windows/issues/6), bad wrapper paths added. So priority was not correct in edge cases.
- Improved developer documentation for `RvmCliList`
- Added CHANGELOG.md

# 1.0.1 - 2025-02-02
- Clarified the supported installation method.

# 1.0.0 - 2024-12-11
- Initial stable release
