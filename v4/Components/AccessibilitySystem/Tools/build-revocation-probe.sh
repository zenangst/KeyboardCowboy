#!/bin/sh
set -eu

package=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
destination=${1:?Usage: sh build-revocation-probe.sh OUTPUT_DIRECTORY}
destination=$(CDPATH= cd -- "$destination" && pwd)
app="$destination/Cowboy AX Revocation Probe.app"

swift build --package-path "$package" -c release --product WindowObservationProbe
bin=$(swift build --package-path "$package" -c release --show-bin-path)
mkdir "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin/WindowObservationProbe" "$app/Contents/MacOS/WindowObservationProbe"
cat > "$app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>org.keyboardcowboy.ax-revocation-probe</string>
  <key>CFBundleExecutable</key>
  <string>WindowObservationProbe</string>
  <key>CFBundleName</key>
  <string>Cowboy AX Revocation Probe</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF
/usr/bin/codesign --sign - "$app"
/usr/bin/codesign --verify --strict "$app"
printf '%s\n' "$app"
