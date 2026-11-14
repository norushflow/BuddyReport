#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

[[ $# -le 1 ]] || { echo 'Usage: ./tools/check.sh [WOW-DIR]' >&2; exit 2; }
command -v luajit >/dev/null || { echo 'LuaJIT is required.' >&2; exit 1; }

toc=BuddyReport.toc
grep -Fxq '## Interface: 120105, 16001' "$toc"
grep -Fxq '## SavedVariables: BuddyReportDB' "$toc"
grep -Fxq '## IconTexture: Interface\AddOns\BuddyReport\Media\Icon.tga' "$toc"
grep -Eq '^## Version: [0-9]+\.[0-9]+\.[0-9]+$' "$toc"
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
