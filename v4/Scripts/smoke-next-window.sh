#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
service="${1:-$root/Service/.build/app/debug/Keyboard Cowboy.app}"
if [[ $# -gt 1 || ! -x "$service/Contents/MacOS/KeyboardCowboy" ]]; then
  print -u2 "Usage: $0 [path to signed Debug Service.app]"
  print -u2 "Build and grant Accessibility to the Debug Service before running."
  exit 1
fi
service="${service:A}"
codesign --verify --deep --strict "$service"

scratch="$(mktemp -d "${TMPDIR:-/tmp}/kc-next-window.XXXXXXXX")"
trap 'rm -rf "$scratch"' EXIT
fixture="$scratch/Next Window Fixture.app"
mkdir -p "$fixture/Contents/MacOS"
plist="$fixture/Contents/Info.plist"
plutil -create xml1 "$plist"
plutil -insert CFBundleIdentifier -string com.zenangst.kc-next-window-fixture "$plist"
plutil -insert CFBundleExecutable -string Fixture "$plist"
plutil -insert CFBundlePackageType -string APPL "$plist"

swiftc -parse-as-library "$root/Scripts/NextWindowSmokeFixture.swift" -o "$fixture/Contents/MacOS/Fixture"
codesign --force --sign - "$fixture"
sw_vers
open -n -W "$fixture" --args "$service" "$scratch/result"
if [[ ! -f "$scratch/result" ]]; then
  print -u2 "The AppKit fixture exited without reporting a result."
  exit 1
fi
cat "$scratch/result"
grep -q '^PASS: ' "$scratch/result"
