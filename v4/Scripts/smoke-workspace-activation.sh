#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
filter=liveWorkspaceActivation
package=Workspaces
if [[ "${1:-}" == --effects && $# -eq 1 ]]; then
  filter=liveWorkspaceEffects
elif [[ "${1:-}" == --app-focus && $# -eq 1 ]]; then
  filter=liveAppFocus
  package=AppFocus
elif [[ "${1:-}" == --tidy && $# -eq 1 ]]; then
  filter=liveWindowTidy
  package=WindowTidy
elif [[ "${1:-}" == --tidy-multi-app && $# -eq 1 ]]; then
  filter=liveMultiAppWindowTidy
  package=WindowTidy
elif (( $# != 0 )); then
  print -u2 "Usage: $0 [--effects|--app-focus|--tidy|--tidy-multi-app]"
  exit 2
fi
scratch="$(mktemp -d "${TMPDIR:-/tmp}/kc-workspace.XXXXXXXX")"
trap 'rm -rf "$scratch"' EXIT
swiftc -parse-as-library "$root/Scripts/WorkspaceSmokeFixture.swift" -o "$scratch/Fixture"
for name in A B; do
  app="$scratch/Workspace Fixture $name.app"
  mkdir -p "$app/Contents/MacOS"
  cp "$scratch/Fixture" "$app/Contents/MacOS/Fixture"
  plist="$app/Contents/Info.plist"
  plutil -create xml1 "$plist"
  plutil -insert CFBundleIdentifier -string "com.zenangst.kc-workspace-fixture-${name:l}" "$plist"
  plutil -insert CFBundleName -string "Workspace Fixture $name" "$plist"
  plutil -insert CFBundleExecutable -string Fixture "$plist"
  plutil -insert CFBundlePackageType -string APPL "$plist"
  codesign --force --sign - "$app"
done

/usr/bin/say "Workspace activation smoke ready. Leave focus alone."
if [[ "$filter" == liveWorkspaceEffects ]]; then
  /usr/bin/say "Testing workspace fill and hiding the other disposable app."
elif [[ "$filter" == liveAppFocus ]]; then
  /usr/bin/say "Testing App Focus activation, hide, and fill."
elif [[ "$filter" == liveWindowTidy ]]; then
  /usr/bin/say "Testing Window Tidy on two disposable windows and one decoy."
elif [[ "$filter" == liveMultiAppWindowTidy ]]; then
  /usr/bin/say "Testing Window Tidy rules across two disposable apps."
else
  /usr/bin/say "Testing workspace A, workspace B, then previous workspace."
fi
KC_WORKSPACES_EFFECTS=0
[[ "$filter" != liveWorkspaceEffects ]] || KC_WORKSPACES_EFFECTS=1
if KC_WORKSPACES_FIXTURES="$scratch" KC_WORKSPACES_EFFECTS="$KC_WORKSPACES_EFFECTS" swift test --package-path "$root/Features/$package" \
    --configuration "${CONFIGURATION:-release}" --filter "$filter"; then
  /usr/bin/say "Workspace activation smoke passed."
else
  /usr/bin/say "Workspace activation smoke did not pass."
  exit 1
fi
