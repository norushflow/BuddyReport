#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

output=dist
if [[ ${1-} == --output-dir && $# -eq 2 ]]; then
    output=$2
elif (( $# )); then
    echo 'Usage: ./tools/release.sh [--output-dir DIR]' >&2
    exit 2
fi
for tool in zip unzip; do command -v "$tool" >/dev/null; done

addon=BuddyReport
toc="$addon.toc"
version=$(awk '/^## Version:/ {print $3; exit}' "$toc")
out="$output/$addon-$version.zip"
[[ ! -e $out && ! -L $out ]] || { printf 'ZIP already exists: %s\n' "$out" >&2; exit 1; }

./tools/check.sh
mkdir -p -- "$output"
stage=$(mktemp -d -- "$output/.package.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
mkdir -- "$stage/$addon"
mapfile -t runtime < <(awk 'NF && $1 !~ /^#/ {print}' "$toc")
cp --parents -- "$toc" "${runtime[@]}" Media/Icon.tga LICENSE "$stage/$addon/"
(
    cd -- "$stage"
    export LC_ALL=C TZ=UTC
    find "$addon" -type f -exec chmod 0644 {} +
    find "$addon" -type f -exec touch -t 198001010000.00 {} +
    find "$addon" -type f -print | sort | ZIPOPT= zip -q -X -9 addon.zip -@
    unzip -tq addon.zip >/dev/null
)
ln -T -- "$stage/addon.zip" "$out"
printf 'Install ZIP: %s\n' "$out"
