# Changelog

## 1.0.2

- Record blocked and forbidden interface actions in diagnostic reports, including the addon and requested function when provided by WoW.
- Count repeated blocks and capture them independently of the Lua error handler and Blizzard error popups.

## 1.0.1

- Avoid redrawing the error counter when its value has not changed; error capture and occurrence counts are unchanged.
- Add Wago project metadata and CurseForge package configuration, with stronger release package validation.

## 1.0.0

- Added standalone Lua error capture for WoW Retail and WoW Forever.
- Added local storage for up to 50 distinct errors with stack traces and occurrence counts.
- Added the `/br` window for creating, copying, and clearing diagnostic reports.
- Added a draggable minimap button that opens the report window, remembers its position, and turns red while errors are saved.
- Fixed a font argument that could interrupt window creation in Retail and Forever.
- Included client and addon versions and addon enablement in the report.
- Added English and German interface text.
