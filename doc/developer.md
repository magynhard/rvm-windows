# Developer documentation

Use native Windows x64 with Crystal 1.20.2+ and Visual Studio C++ build tools.
No Node.js, npm, yarn, or external shards are required for the Crystal project.

```powershell
shards build
crystal spec
crystal run scripts/build.cr
crystal run scripts/package.cr
```

`shards build` produces a dynamic development executable. The build/package
scripts produce a release/static executable with only Windows DLL imports.
Always use root `rvm.cmd`/`rvm.ps1` to retain session changes across commands.

Specs have a fresh temporary RVM home and configured data directory per example.
Use `Fixtures.with_home` for configuration and session tests. Do not call `init`,
`fix`, `kit`, registry-mutating installer paths, or process-killing methods against
the real host. For a task that shells out, prefer pure command builders or a
compiled executable fixture instead of interacting with a real Ruby installation.

See README for live/differential test flags. The optional JavaScript reference
test is the only development feature that needs Node and the old checkout.
