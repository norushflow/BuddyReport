# BuddyBugReport – Lua Error Reports

**Project summary**

Create a copyable Lua error report with stack traces, error counts, and your addon list in one click. Supports WoW Retail and WoW Forever.

**Category**

Development Tools

**Project description**

BuddyBugReport gives you one place to collect the details an addon author needs to reproduce a Lua error. Click the BuddyReport minimap icon or type `/br`, then click **Create report**. Copy the text into a GitHub issue or CurseForge comment after reviewing it for private details.

Drag the minimap icon to move it along the edge. It remembers its position and turns red while there are saved errors.

Each report includes the WoW edition, version, build and language, the installed addons with their versions and enablement, and up to 50 distinct Lua errors with stack traces and occurrence counts. The report also counts blocked and forbidden interface actions and names the addon and function when WoW supplies them. The error history is stored locally and can be cleared in the same window.

Extract the ZIP so the `BuddyReport` folder sits inside your client's `Interface/AddOns` folder. The same package supports **WoW Retail 12.1.5** and **WoW Forever 1.60.1**. BuddyReport runs independently and leaves your Blizzard error popup setting as configured.

The addon's name in WoW is **BuddyReport**. The interface is available in English and German.
