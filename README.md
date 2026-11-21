# BuddyReport

BuddyReport turns recorded Lua errors into one copyable diagnostic report. It includes the client version, build and language, the installed addons and their enablement, and saved errors with stack traces and occurrence counts. It also records blocked and forbidden interface actions, with the addon and function when WoW supplies them.

## Supported clients

| WoW client | Version | TOC interface |
| --- | --- | --- |
| Retail | 12.1.5 | 120105 |
| Forever | 1.60.1 | 16001 |

The same ZIP works in both clients. BuddyReport runs on its own.

## Install and use

1. Extract the release ZIP. Put the `BuddyReport` folder in `_retail_/Interface/AddOns/` or `_forever_/Interface/AddOns/`.
2. Log in, reproduce the error, and click the BuddyReport minimap icon or enter `/br` in chat.
3. Click **Create report**. With the report focused, use **Ctrl+A**, then **Ctrl+C**.
4. Review the text and remove any private details before pasting it into a GitHub issue or a CurseForge comment. In a GitHub issue, paste it inside a code block to preserve stack formatting.

**Clear errors** removes BuddyReport's records and empties the current report. WoW saves the records during a normal logout, exit, or UI reload. BuddyReport keeps up to 50 distinct message-and-stack combinations. New distinct errors replace the oldest stored entries. Very long messages and stacks are truncated.

Drag the minimap icon with the left mouse button to move it along the edge. BuddyReport remembers its position. The icon turns red while there are saved errors and returns to its usual colors when you clear them.

## Capture and privacy

BuddyReport captures Lua errors reaching the installed client handler after BuddyReport loads. If the installed BugGrabber owns the handler, BuddyReport can receive new error notifications from it. A conflicting collector or restricted client data can limit collection. The report indicates the capture source and whether Blizzard's error popups are enabled. BuddyReport leaves the popup setting as configured.

Data stays in local WoW SavedVariables. BuddyReport omits stack locals and redacts recognizable account paths, player GUIDs, BattleTags, email addresses and protected name placeholders. Error text from other addons can still contain personal information. The addon list checks the current character's enablement using the same client API as Blizzard's addon list. The character identifier is used only for that query.

The UI uses WoW's default font. If you have Expressway licensed for this use, you can place a local copy at `BuddyReport/Media/Expressway.ttf`; the UI will use it where the font covers the client locale. See [Typodermic's font licensing guide](https://typodermicfonts.com/license/).

[Changelog](CHANGELOG.md) · [MIT license](LICENSE)
