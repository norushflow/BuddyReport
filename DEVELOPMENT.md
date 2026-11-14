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

Run `./tools/release.sh` to test and build `dist/BuddyReport-1.0.0.zip`.
The script uses the Buddy project ZIP layout and deterministic package format.
Use the Fedora commands above to install a checked build for the smoke test.

Push the checked commit to `main` in the BuddyReport repository. Run
`gh workflow run release.yml --ref main --repo norushflow/BuddyReport`.
The workflow builds the ZIP, downloads the draft's uploaded asset and compares
its bytes before publishing. In CurseForge, use [CURSEFORGE.md](CURSEFORGE.md),
`branding/BuddyReport-400.png` and the same verified ZIP. Assign both target
clients to the file.
