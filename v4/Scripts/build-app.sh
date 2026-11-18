#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
SERVICE_DIR="$ROOT_DIR/Service"
export CONFIGURATION="${CONFIGURATION:-debug}"
export SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"
APP_PATH="$SERVICE_DIR/.build/app/$CONFIGURATION/Keyboard Cowboy.app"
EDITOR_PATH="$("$ROOT_DIR/Editor/Scripts/build-app.sh")"

swift build --package-path "$SERVICE_DIR" --configuration "$CONFIGURATION" --product KeyboardCowboy >&2
BIN_DIR="$(swift build --package-path "$SERVICE_DIR" --configuration "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Helpers"
cp "$SERVICE_DIR/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$BIN_DIR/KeyboardCowboy" "$APP_PATH/Contents/MacOS/KeyboardCowboy"
ditto "$EDITOR_PATH" "$APP_PATH/Contents/Helpers/Keyboard Cowboy Editor.app"
codesign --force --sign "$SIGNING_IDENTITY" "$APP_PATH"

print -r -- "$APP_PATH"
