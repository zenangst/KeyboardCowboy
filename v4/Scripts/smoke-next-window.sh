#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
fixture_args=()
if [[ "${1:-}" == --spatial || "${1:-}" == --multi-display || "${1:-}" == --cross-app || "${1:-}" == --space-ring ]]; then
  fixture_args=("$1")
  shift
fi
service="${1:-$root/Service/.build/app/debug/Keyboard Cowboy.app}"
if [[ $# -gt 1 || ! -x "$service/Contents/MacOS/KeyboardCowboy" ]]; then
  print -u2 "Usage: $0 [--spatial|--multi-display|--cross-app|--space-ring] [path to signed Debug or Window Focus validation Service.app]"
  print -u2 "Build and grant Accessibility to that Service before running."
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
plutil -insert CFBundleName -string 'Next Window Fixture' "$plist"
plutil -insert CFBundleExecutable -string Fixture "$plist"
plutil -insert CFBundlePackageType -string APPL "$plist"

swiftc -parse-as-library "$root/Scripts/NextWindowSmokeFixture.swift" -o "$fixture/Contents/MacOS/Fixture"
if [[ "${fixture_args[1]:-}" == --cross-app || "${fixture_args[1]:-}" == --space-ring ]]; then
  peer="$scratch/Next Window Peer.app"
  ditto "$fixture" "$peer"
  plutil -replace CFBundleIdentifier -string com.zenangst.kc-next-window-peer "$peer/Contents/Info.plist"
  plutil -replace CFBundleName -string 'Next Window Peer' "$peer/Contents/Info.plist"
  codesign --force --sign - "$peer"
fi
codesign --force --sign - "$fixture"
sw_vers
/usr/bin/say "Window Focus smoke test ready. Leave the fixture frontmost."
/usr/bin/say "Running the window focus checks."
if ! open -n -W "$fixture" --args "$service" "$scratch/result" "${fixture_args[@]}"; then
  /usr/bin/say "Window Focus smoke test did not pass."
  exit 1
fi
if [[ ! -f "$scratch/result" ]]; then
  /usr/bin/say "Window Focus smoke test did not pass."
  print -u2 "The AppKit fixture exited without reporting a result."
  exit 1
fi
cat "$scratch/result"
if grep -q '^PASS: ' "$scratch/result"; then
  /usr/bin/say "Window Focus smoke test passed."
else
  /usr/bin/say "Window Focus smoke test did not pass."
  exit 1
fi
