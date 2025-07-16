#!/bin/zsh

source .env > /dev/null 2>&1

VERSION_NUMBER=`sed -n '/MARKETING_VERSION/s/.*: *"\([0-9.]*\)".*/\1/p' ./Tuist/ProjectDescriptionHelpers/Target+MainApp.swift`
BUILD_PATH="Build/Releases/$APP_NAME $VERSION_NUMBER.dmg"

echo "💮 Staple the .dmg"
xcrun stapler staple -v "$BUILD_PATH"
echo "✅ Done!: $BUILD_PATH"
