#!/bin/zsh

source .env

VERSION_NUMBER=`sed -n '/MARKETING_VERSION/s/.*: *"\([0-9.]*\)".*/\1/p' ./Project.swift`
BUILD_FOLDER="Build/Releases"
ZIPPED_FILE_PATH="$BUILD_FOLDER/$APP_NAME.zip"

echo "🚀 Creating a release"
gh release create -p -t "$VERSION_NUMBER" -n "" $VERSION_NUMBER
echo "🗳 Uploading zip-file"
gh release upload $VERSION_NUMBER "$ZIPPED_FILE_PATH"
