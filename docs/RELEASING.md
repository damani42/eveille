# Release preparation

## Verification

Run from a clean checkout on macOS:

```sh
./scripts/test.sh
./scripts/build.sh --universal
file build/Eveille.app/Contents/MacOS/Eveille
codesign --verify --strict --verbose=2 build/Eveille.app
cd dist
shasum -a 256 -c Eveille-macos-universal.zip.sha256
```

The automated tests cover creation and replacement of real display/system power
assertions, stop and cleanup, deadline preservation, expiry, duration changes, and
unlimited sessions. GitHub-hosted runners may differ from a logged-in desktop; an
assertion failure should fail the job and be investigated rather than ignored.

## Manual checklist

These checks are pending for the public preview. Record macOS versions and Mac
architectures when completing them. Do not mark them passed based on compilation.

- [ ] Opening the app shows a sun in the menu bar and no Dock icon.
- [ ] All labels are in English and readable in light and dark appearance.
- [ ] Turning keep-awake off changes the icon to a moon and removes its assertion.
- [ ] Re-enabling keep-awake creates a new assertion.
- [ ] Changing display mode preserves the countdown.
- [ ] Duration choices restart an active countdown; expiry stops it.
- [ ] Reopening the app does not create duplicate status items.
- [ ] Reopening after quitting restores preferences and starts a new session.
- [ ] Quitting removes Eveille's assertion; other apps' assertions remain alone.
- [ ] Manual locking and manual sleep still work.
- [ ] The app works on an Intel Mac and an Apple Silicon Mac.
- [ ] The minimum supported macOS version has been checked on an actual system.
- [ ] The ZIP extracts with executable permissions intact.

Use `pmset -g assertions` to inspect entries named
`Eveille - keeping your Mac awake`. Other apps can prevent sleep independently.

## Public package

1. Keep the version in `Resources/Info.plist`, the About text, and the changelog aligned.
2. Run the checks above. Use a preview release while manual checks remain incomplete.
3. Attach `dist/Eveille-macos-universal.zip` and its `.sha256` file to the release.
4. Use [RELEASE_NOTES.md](RELEASE_NOTES.md) as the starting description.
5. State explicitly whether the package is notarized. Do not describe an ad hoc
   signature as Developer ID signing or Apple approval.

Only source, documentation, and workflow files belong in Git. Build outputs,
certificates, local preferences, credentials, and machine-specific files do not.

## Developer ID signing and notarization

The current scripts deliberately produce a local ad hoc signature. For a notarized
release, the maintainer needs their own Apple Developer ID Application certificate
and notarization credentials. Keep private keys and credentials outside the repository.

Follow [Apple's notarization guide](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
to sign with the hardened runtime, submit to the notary service, staple the ticket,
verify the result, and recreate the ZIP and checksum. A source release does not
require an Apple Developer account.
