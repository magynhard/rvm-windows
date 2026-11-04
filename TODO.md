# TODO

## Windows code signing and publisher verification

- [ ] Choose a trusted code-signing provider and publisher identity:
  - [SignPath Foundation](https://signpath.org/) for qualifying open-source projects.
  - A commercial code-signing certificate with a verified publisher identity.
  - [Azure Artifact Signing](https://learn.microsoft.com/en-us/azure/artifact-signing/),
    subject to identity and regional eligibility.
- [ ] Complete the provider's verification and approval process.
- [ ] Integrate Authenticode signing into the release pipeline:
  - Sign `bin/rvm.exe` before creating the ZIP and setup.
  - Sign the uninstaller during NSIS compilation using `!uninstfinalize`.
  - Sign the final setup executable.
  - Use SHA-256 and an RFC 3161 timestamp.
  - Keep credentials outside the repository and use a consistent signing identity.
- [ ] Verify signatures and publisher names before uploading release assets.
- [ ] Test downloaded releases on a clean Windows system, including SmartScreen.

Publisher/version metadata is already included in setup, but does not replace a
trusted signature. Signing identifies the publisher; SmartScreen reputation must
still accumulate, and even EV certificates do not guarantee immediate trust.
Self-signed certificates are not suitable for general public distribution.

Reference: [Microsoft code-signing options](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options).

## Native npm migration release acceptance

- [ ] In a disposable Windows VM, migrate an actual 1.0.8 installation via
  setup, npm update, and the old `rvm get`; repeat in CMD and PowerShell.
- [ ] Verify original configuration bytes/extension fields, active sessions,
  installed Ruby files, custom data directories and long PATH values survive.
- [ ] Check deferred cleanup with active legacy/npm processes, restricted
  permissions, interrupted setup and subsequent retry/rollback.
- [ ] Verify the signed setup bundled in the npm tarball matches the release.
- [ ] Publish the new bridge version under the existing `rvm-windows` package
  name only after acceptance; npm script-approval policies may require opt-in.
- [ ] If consolidating repositories, update release endpoints, npm metadata,
  CI and documentation together, preserving history and existing version tags.
- [ ] Retire the migration class and legacy updater fixtures only after old
  installations no longer need support; do not remove the ongoing npm bridge.
