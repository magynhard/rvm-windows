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
