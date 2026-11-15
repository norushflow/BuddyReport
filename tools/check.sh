#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

[[ $# -le 1 ]] || { echo 'Usage: ./tools/check.sh [WOW-DIR]' >&2; exit 2; }
command -v luajit >/dev/null || { echo 'LuaJIT is required.' >&2; exit 1; }

toc=BuddyReport.toc
grep -Fxq '## Interface: 120105, 16001' "$toc"
grep -Fxq '## SavedVariables: BuddyReportDB' "$toc"
grep -Fxq '## X-Curse-Project-ID: 1804151' "$toc"
grep -Fxq '## X-Wago-ID: ZKbq0461' "$toc"
[[ $(grep -Ec '^## (X-Curse-Project-ID|X-Wago-ID):' "$toc") == 2 ]] ||
    { echo 'Duplicate project metadata in TOC.' >&2; exit 1; }
grep -Fxq '## IconTexture: Interface\AddOns\BuddyReport\Media\Icon.tga' "$toc"
grep -Eq '^## Version: [0-9]+\.[0-9]+\.[0-9]+$' "$toc"
[[ $(grep -c '^## Version:' "$toc") == 1 && $(grep -c '^## Interface:' "$toc") == 1 ]] ||
    { echo 'Duplicate version or interface metadata in TOC.' >&2; exit 1; }
awk -v addon='BuddyReport' -v notes='CHANGELOG.md' \
    -v required='AGENTS.md CHANGELOG.md CURSEFORGE.md DEVELOPMENT.md README.md branding tests tools TEMP dist Media/Expressway.ttf Media/MORPHEUS.TTF' '
    BEGIN { split(required, paths); for (i in paths) allowed[paths[i]]=1 }
    /^package-as:/ { if (NF != 2 || $2 != addon) exit 1; names++; next }
    /^manual-changelog:[[:space:]]*$/ { manual++; next }
    /^[[:space:]]+filename:/ { if (NF != 2 || $2 != notes) exit 1; filenames++; next }
    /^[[:space:]]+markup-type:/ { if (NF != 2 || $2 != "markdown") exit 1; markup++; next }
    /^ignore:[[:space:]]*$/ { ignore++; next }
    /^[[:space:]]+- / && ignore { if (NF != 2 || !allowed[$2] || seen[$2]++) exit 1; next }
    /^[[:space:]]*(#.*)?$/ { next }
    { exit 1 }
    END {
        if (names != 1 || manual != 1 || filenames != 1 || markup != 1 || ignore != 1) exit 1
        for (i in paths) if (!seen[paths[i]]) exit 1
    }
' .pkgmeta || { echo 'Invalid CurseForge package metadata.' >&2; exit 1; }
if grep -Ei '^##[[:space:]]*(Dependencies|RequiredDeps|OptionalDeps|LoadOnDemand|SavedVariablesPerCharacter):' "$toc"; then
    echo 'Unexpected loading or dependency metadata.' >&2
    exit 1
fi

if [[ $# -eq 1 ]]; then
    awk -F '|' '
        $2 == 1 && $NF == "wow" && $(NF-2) ~ /^12\.1\.5\./ { retail=1 }
        $2 == 1 && $NF == "wowf" && $(NF-2) ~ /^1\.60\.1\./ { forever=1 }
        END { exit !(retail && forever) }
    ' "$1/.build.info"
    echo 'TOC interfaces match installed Retail and Forever products.'
fi

mapfile -t runtime < <(awk 'NF && $1 !~ /^#/ {print}' "$toc")
[[ ${runtime[*]} == 'Core.lua UI.lua' ]]
luajit - "${runtime[@]}" tests/test_report.lua <<'LUA'
for _, path in ipairs(arg) do assert(loadfile(path)) end
local file = assert(io.open("Media/Icon.tga", "rb"))
local icon = file:read("*a")
file:close()
local imageType, width, widthHi, height, heightHi, bits =
    icon:byte(3), icon:byte(13, 17)
assert(imageType == 2 and width == 64 and height == 64 and widthHi == 0 and heightHi == 0)
assert((bits == 24 or bits == 32) and #icon == 18 + 64 * 64 * bits / 8)
LUA
luajit tests/test_report.lua
