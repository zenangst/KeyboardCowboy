#!/bin/zsh

set -euo pipefail

ROOT_DIR="${0:A:h:h}"
PRODUCT_NAME="Keyboard Cowboy"
EXECUTABLE_NAME="v4"
CONFIGURATION="${CONFIGURATION:-debug}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"
ENTITLEMENTS_PATH="$ROOT_DIR/Resources/V4.entitlements"
INFO_PLIST_PATH="$ROOT_DIR/Resources/Info.plist"
APP_BUILD_DIR="$ROOT_DIR/.build/app/$CONFIGURATION"
APP_PATH="$APP_BUILD_DIR/$PRODUCT_NAME.app"

mkdir -p "$APP_BUILD_DIR"

swift build --configuration "$CONFIGURATION" --product "$EXECUTABLE_NAME"

BIN_DIR="$(swift build --configuration "$CONFIGURATION" --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$EXECUTABLE_NAME"

if [[ ! -f "$EXECUTABLE_PATH" ]]; then
  print -u2 "error: built executable not found at $EXECUTABLE_PATH"
  exit 1
fi

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"

cp "$INFO_PLIST_PATH" "$APP_PATH/Contents/Info.plist"
cp "$EXECUTABLE_PATH" "$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
chmod +x "$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"

codesign --force --sign "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS_PATH" "$APP_PATH"

print "$APP_PATH"
