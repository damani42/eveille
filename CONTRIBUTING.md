# Contributing

Thanks for helping improve Eveille. Small, focused changes are welcome.

## Report a problem

Open an issue with your macOS version, Mac architecture (Apple Silicon or Intel),
Eveille version, what you expected, and the steps to reproduce the problem.
Remove personal information from screenshots and logs before posting.

## Work on the code

1. Fork the repository and create a branch.
2. Keep code, comments, interface text, and documentation in English.
3. Run `./scripts/test.sh` and `./scripts/build.sh --universal`.
4. Check relevant items in the [manual checklist](docs/RELEASING.md).
5. Open a pull request describing the change and how you verified it.

Keep the app small, native, offline, and free of third-party runtime dependencies.
Preserve assertion cleanup on stop, expiry, and termination. Changing display mode
must preserve the deadline and acquire a new assertion before releasing the old one.

By contributing, you agree to license your contribution under the project's MIT License.
