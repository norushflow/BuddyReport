# Development and release

Run `./tools/check.sh` for the focused LuaJIT tests and TOC checks. Use
`./tools/check.sh "/path/to/World of Warcraft"` to check both interfaces
against the active products in the local client's `.build.info` as well.

## Capture API

[Retail 12.1.5 UI source](https://github.com/Gethe/wow-ui-source/blob/297d7aa/Interface/AddOns/Blizzard_ScriptErrors/Blizzard_ScriptErrors.lua)
shows that Blizzard protects registration through `AddLuaErrorHandler` with
`issecure()`. BuddyReport uses the client Lua error-handler API and chains
the handler it finds. Both target executables expose the Lua error-handler
and stack APIs. The installed BugGrabber v12.1.1 takes ownership of its
handler and emits `BugGrabber.BugGrabbed`. BuddyReport can observe that event
without creating a dependency. There is no guaranteed global feed of errors
that are hidden before load, handled privately, or made inaccessible by
client restrictions.

## Client smoke test

After technical checks for a gameplay change, end the test report with the
Fedora install command for each affected client. Run the applicable command
in the local Fedora terminal.

| Client | Fedora command |
| --- | --- |
| Retail | `cd /mnt/UserData/Dokumente/ChatGPT/wow_addon && ./tools/spieltest.sh BuddyReport-Retail` |
| Forever | `cd /mnt/UserData/Dokumente/ChatGPT/wow_addon && ./tools/spieltest.sh BuddyReport-Forever` |

WoW can stay open. Once installation succeeds, enter `/reload` in WoW chat.

Test separately in Retail and Forever with just BuddyReport enabled. In
Forever, log in before testing `/br`.

1. Check the name, icon, enabled state and version in the add-on list.
   In game, check the minimap icon and tooltip. Click the icon to open and
   close the report window, then check that `/br` opens the same window.
   Drag the icon along the minimap edge and verify its position after a reload.
2. Set `/console scriptErrors 0`. Open `/br`, create an empty report and
   verify that the game edition, build, language and addon inventory are present.
3. Run the same chat command twice on separate submissions:
   `/run error("BuddyReport smoke test")`
   Generate a new report and check the message, originating stack, and count of two.
   Verify that the minimap icon turns red and stays red until the errors are cleared.
4. Copy the entire report via Ctrl+A and Ctrl+C, paste it in a local editor and
   check that the last stack line is present. Repeat with a long report and verify
   wheel scrolling and selection.
5. Reload the UI and check that the error remains. Clear errors, reload and
   verify an empty history. Repeat capture with `scriptErrors 1` and verify the
   native popup. Restore the original setting.
6. With BugGrabber enabled, reproduce a new error and check the report's
   capture source and occurrence count.

The local Lua tests exercise simulated client APIs. Client rendering, clipboard,
and runtime behavior are covered by the smoke test above.

## Build and publish

Publish only on an explicit release request; failed checks block publication. Reuse a confirmed smoke test of the same code.

1. Check the remote, update the TOC version and English `CHANGELOG.md`, then commit and push to `main`.
2. Run `gh workflow run release.yml --ref main --repo norushflow/BuddyReport`. It tests, builds and verifies the ZIP before publishing the release and tag. Confirm the commit and ZIP once. A local `./tools/release.sh` build also runs the checks; use it only when a local ZIP or smoke test is needed.
3. CurseForge: check webhook-created files, including pending files. Only if absent and no upload is running, upload the same GitHub ZIP for **both clients**, using `CHANGELOG.md`. Report pending moderation without waiting. See `CURSEFORGE.md` only for setup or upload details.
4. Wago: check the project and that the version is absent, then run `wago-release.yml` once with `tag=<tag>`, `dry_run=false`, `confirm_new=<tag>`. Report GitHub, CurseForge and Wago status separately.

Wago requires secret `WAGO_API_TOKEN` and variable `WAGO_PROJECT_ID` matching the TOC. Dry run remains the default; an unchanged, verified setup needs no extra dry run. For an uncertain upload, check the platform first; use `recover_status_id` only if the version is confirmed absent. Never retry blindly or expose secrets.
