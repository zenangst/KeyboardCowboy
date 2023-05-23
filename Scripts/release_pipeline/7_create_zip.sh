#!/bin/zsh

source .env

VERSION_NUMBER=`sed -n '/MARKETING_VERSION/s/.*: *"\([0-9.]*\)".*/\1/p' ./Project.swift`
BUILD_FOLDER="Build/Releases"
BUILD_PATH="$BUILD_FOLDER/$APP_NAME $VERSION_NUMBER.dmg"

echo "🤐 Zipping ..."

zip "$BUILD_FOLDER/Keyboard Cowboy.zip" "$BUILD_PATH"
