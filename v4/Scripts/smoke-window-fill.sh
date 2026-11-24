#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
display="${1:-primary}"
if [[ $# -gt 1 || ( "$display" != primary && "$display" != secondary ) ]]; then
  print -u2 "Usage: $0 [primary|secondary]"
  exit 2
fi
scratch="$(mktemp -d "${TMPDIR:-/tmp}/kc-fill.XXXXXXXX")"
trap 'rm -rf "$scratch"' EXIT
fixture="$scratch/Center Fixture.app"
mkdir -p "$fixture/Contents/MacOS"
plist="$fixture/Contents/Info.plist"
plutil -create xml1 "$plist"
plutil -insert CFBundleIdentifier -string com.zenangst.kc-center-fixture "$plist"
plutil -insert CFBundleName -string 'Center Fixture' "$plist"
plutil -insert CFBundleExecutable -string Fixture "$plist"
plutil -insert CFBundlePackageType -string APPL "$plist"
swiftc -parse-as-library "$root/Scripts/WindowFillSmokeFixture.swift" -o "$fixture/Contents/MacOS/Fixture"
codesign --force --sign - "$fixture"
sw_vers
KC_FILL_SMOKE_FIXTURE="$fixture" KC_FILL_SMOKE_DISPLAY="$display" \
  swift test --package-path "$root/Features/WindowManagement" \
    --configuration "${CONFIGURATION:-debug}" --filter liveFillTiming
