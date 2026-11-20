# BuddyReport

One shared WoW addon for Retail and Forever. BuddyReport.toc defines the client interfaces, release version and load order.

- Keep the addon standalone with local SavedVariables and a single report window.
- Run `./tools/check.sh` or build the ZIP with `./tools/release.sh`.
- Preserve existing changes; read only relevant files and diffs. Follow the parent `AGENTS.md` when working in the shared project.
- Publish only on an explicit release request. Read the release section in DEVELOPMENT.md then; use existing workflows without duplicate checks.
- Keep `.pkgmeta` aligned with the release ZIP and use `CHANGELOG.md` for the CurseForge changelog.
- Use the client smoke test in DEVELOPMENT.md to verify runtime behavior.
- End each completed test report with a copyable Fedora command. For a client smoke test, give the install command from DEVELOPMENT.md for each affected client even if installation already succeeded.
- Keep licensed local fonts out of Git and the release ZIP.
