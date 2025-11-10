# 1.0.3 - 2025-11-10
- Add CLI support to set rvm data directory, via `rvm config set data <path>`, thanks to [paul-c-hartman](https://github.com/paul-c-hartman)
- See pull request [#8](https://github.com/magynhard/rvm-windows/pull/8)

# 1.0.2 - 2025-09-07
- Fix [#3](https://github.com/magynhard/rvm-windows/issues/3), honor `MSYS2_PATH` env variable, when installing new rubies.
  -  This allows to use a central MSYS2 installation, instead of installing a new one for each ruby version.
- Added interactive REPL to test the `rvm-windows` environment, run it by `yarn test-cli`
- Updated dependencies
- Fix [#6](https://github.com/magynhard/rvm-windows/issues/6), bad wrapper paths added. So priority was not correct in edge cases.
- Improved developer documentation for `RvmCliList`
- Added CHANGELOG.md

# 1.0.1 - 2025-02-02
- Added info, that yarn is not supported for installation of `rvm-windows`, use npm instead.

# 1.0.0 - 2024-12-11
- Initial stable release