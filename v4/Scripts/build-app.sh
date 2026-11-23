#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
SERVICE_DIR="$ROOT_DIR/Service"
export CONFIGURATION="${CONFIGURATION:-debug}"
if [[ "$CONFIGURATION" == debug && -z "${SIGNING_IDENTITY:-}" ]]; then
  SIGNING_IDENTITY="$(git -C "$ROOT_DIR" config --local --get keyboardcowboy.debugSigningIdentity || true)"
fi
export SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"
build_flags=()
sign_flags=()
app_configuration="$CONFIGURATION"
if [[ "${WINDOW_FOCUS_VALIDATION:-0}" == 1 ]]; then
  if [[ "$CONFIGURATION" != release || "$SIGNING_IDENTITY" == - ]]; then
    print -u2 "Window Focus validation requires CONFIGURATION=release and a Developer ID SIGNING_IDENTITY."
    exit 1
  fi
  build_flags=(-Xswiftc -D -Xswiftc WINDOW_FOCUS_VALIDATION)
  sign_flags=(--options runtime)
  app_configuration=window-focus-validation
fi
APP_PATH="$SERVICE_DIR/.build/app/$app_configuration/Keyboard Cowboy.app"
EDITOR_PATH="$("$ROOT_DIR/Editor/Scripts/build-app.sh")"

swift build --package-path "$SERVICE_DIR" --configuration "$CONFIGURATION" --product KeyboardCowboy "${build_flags[@]}" >&2
BIN_DIR="$(swift build --package-path "$SERVICE_DIR" --configuration "$CONFIGURATION" --show-bin-path "${build_flags[@]}")"

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Helpers"
cp "$SERVICE_DIR/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$BIN_DIR/KeyboardCowboy" "$APP_PATH/Contents/MacOS/KeyboardCowboy"
ditto "$EDITOR_PATH" "$APP_PATH/Contents/Helpers/Keyboard Cowboy Editor.app"
if [[ "${WINDOW_FOCUS_VALIDATION:-0}" == 1 ]]; then
  codesign --force --sign "$SIGNING_IDENTITY" --options runtime --preserve-metadata=entitlements \
    "$APP_PATH/Contents/Helpers/Keyboard Cowboy Editor.app"
fi
codesign --force --sign "$SIGNING_IDENTITY" "${sign_flags[@]}" "$APP_PATH"
if [[ "${WINDOW_FOCUS_VALIDATION:-0}" == 1 ]]; then
  codesign --verify --deep --strict -R='anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.13] exists' "$APP_PATH"
fi

print -r -- "$APP_PATH"
