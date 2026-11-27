#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
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
/usr/bin/say "Testing workspace A, workspace B, then previous workspace."
if KC_WORKSPACES_FIXTURES="$scratch" swift test --package-path "$root/Features/Workspaces" \
    --configuration "${CONFIGURATION:-release}" --filter liveWorkspaceActivation; then
  /usr/bin/say "Workspace activation smoke passed."
else
  /usr/bin/say "Workspace activation smoke did not pass."
  exit 1
fi
