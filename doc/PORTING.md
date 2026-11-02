# Porting contract

Source: `magynhard/rvm-windows` at `ecf0758c6027977c89f4306e1933b871ebda4c41`.

* Preserve source classes and task/wrapper file boundaries; use Crystal snake_case.
* One native Windows x64 executable, including internal wrapper subcommands.
* Preserve ~/.rvm.json (including unknown JSON keys), ~/.rvm/sessions,
  RVM_SESSION, C:/ProgramData/rvm and existing installed Ruby environments.
* Preserve batch environment save/restore, command forwarding and exit status.
* No npm/Node runtime dependency. Updates will use GitHub Releases and NSIS.
* Specs must isolate configuration, sessions, downloads and wrappers. Never run
  installers, kill MSYS processes, change the registry or user PATH in tests.
* Commit compilable milestones. Native installation/update validation is separate
  from automated tests and must not touch an existing installation implicitly.

## Milestones

1. Native executable and Crystal project skeleton.
2. Configuration, version resolution and all five wrapper entrypoints.
3. CLI tasks and equivalent tests, plus isolated integration coverage.
4. Distribution, NSIS setup, CI and documented validation/limitations.
