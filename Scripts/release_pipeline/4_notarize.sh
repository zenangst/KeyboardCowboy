#!/bin/zsh

source .env > /dev/null 2>&1

VERSION_NUMBER=`sed -n '/MARKETING_VERSION/s/.*: *"\([0-9.]*\)".*/\1/p' ./Tuist/ProjectDescriptionHelpers/Target+MainApp.swift`
BUILD_PATH="Build/Releases/$APP_NAME $VERSION_NUMBER.dmg"

echo "🏓 Notarizing"
# Notarize
OUTPUT=`xcrun notarytool \
  submit \
  --apple-id $USERNAME \
  --password $APP_SPECIFIC_PASSWORD \
  --team-id $TEAM_ID \
  --wait \
  "$BUILD_PATH"`

echo $OUTPUT
