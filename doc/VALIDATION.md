# Validation and release checklist

## Automated checks performed locally (Windows x64 / Crystal 1.20.2)

* Original JavaScript suite: 9 Jasmine specs passed, including live archives.
* Crystal suite: 64 offline examples, 73 with all three optional checks enabled;
  all passed locally. Equivalent original cases plus isolated configuration,
  sessions, numeric version matching, project inheritance, wrapper naming,
  subprocess protocol, CLI dispatch, HTTP redirects/cache errors and proxy tests.
* Original regression cases retained: installation paths with spaces; wrapped
  exit code 42 after cleanup; success preserved despite post-hook exit code 17.
  Wrapper tests also use an executable path containing `Matthäus` and spaces in
  CMD and PowerShell, require empty stderr, and verify CRLF output independent
  of source checkout line endings (LF-only UTF-8 wrappers truncate commands).
* Real native wrapper: argument forwarding, command fallback and status 9009.
* Parent CMD and PowerShell session creation and persistence across consecutive
  EXE calls. PATH-helper previews preserve long/unexpanded values without writes.
* CMD built-ins (`ver`, `echo`, `exit`), quoted batch paths/arguments, command
  chaining, redirection and failure statuses covered by shell regression tests.
  `info` tested in-process and through development/static packaged executables,
  using a compiled Ruby-version fixture rather than a real Ruby installation.
* Opt-in live archive test: historical Ruby versions available over native TLS.
* Opt-in differential test: actual JavaScript version resolution, list output
  and wrapper selection compared to the Crystal results, plus Chalk color
  comparisons with the intentional green-to-blue primary-color replacement.
  Semantic green/red status colors are retained.
* Missing-version explanations for install, upgrade, kick, reinstall, uninstall
  and use, plus every help task description, compared verbatim with the original.
  Aliases, empty arguments, separately colored upgrade alternatives and the
  complete upgrade explanation in development/static executables are covered.
* ANSI palette, terminal/pipe detection, NO_COLOR/FORCE_COLOR, help alignment,
  color-free configuration/session writes and forced-color protocol safety tested.
* Release/static executable built and package smoke-tested with a PATH containing
  only Windows directories (no Node/Crystal or third-party runtime DLLs).
* PE imports inspected with dumpbin: Windows system DLLs only.
* ZIP package and NSIS 3.13 setup successfully compiled locally. The setup
  executable was not installed or executed against the host.
  Package artwork lives in `src/assets/img`; the README points to the new SVG,
  and obsolete `rvm_cmd*.png` logos are excluded.

No tests installed Rubies/gems, killed MSYS, modified the user's registry/PATH,
or touched the real RVM configuration. Original support-file hashes are preserved.

## Before publishing a stable replacement

- [ ] Install NSIS setup on a disposable Windows 10/11 VM as a standard user.
- [ ] Install over the same directory; verify existing Ruby environments,
      JSON extension fields, active session files and long PATH values survive.
- [ ] Validate PowerShell launcher/session behavior interactively (scripted
      subprocess session tests already pass).
- [ ] Exercise install, reinstall, same-minor side-by-side install, upgrade,
      uninstall, kick, scan, system and legacy kit recipes with real Rubies.
- [ ] Test real authenticated HTTP CONNECT proxy, corporate CA configuration and
      interrupted large downloads. Offline proxy specs cover HTTP auth and CONNECT
      refusal; they do not certify every real-world proxy implementation.
- [ ] Publish test assets in a controlled release and exercise the complete
      `rvm get` wait/download/replace/reinitialize path on a disposable machine.
- [ ] Test uninstall and switching back to the Node implementation (`rvm fix`).
- [ ] Audit and bundle all third-party static-link licenses/notices for the exact
      Crystal toolchain: Crystal, Boehm GC, PCRE2, OpenSSL, zlib, iconv and platform
      runtime components. The source project's MIT license alone is insufficient.
- [ ] Decide code signing and artifact checksum publication policy.
- [ ] Run the prepared GitHub Actions workflow in the new remote repository.

The automated checks are not a claim that destructive installation/update flows
have already been accepted on a real existing installation.
