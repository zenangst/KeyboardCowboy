#!/bin/zsh

source .env

VERSION_NUMBER=`sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION: //;s/;//;s/^[[:space:]]*//;p;q;}' ./project.yml`
BUILD_PATH="Build/Releases/$APP_NAME $VERSION_NUMBER.dmg"

echo "💮 Staple the .dmg"
xcrun stapler staple -v "$BUILD_PATH"
echo "✅ Done!: $BUILD_PATH"
