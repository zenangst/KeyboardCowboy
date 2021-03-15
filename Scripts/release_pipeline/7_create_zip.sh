#!/bin/zsh

source .env

VERSION_NUMBER=`sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION: //;s/;//;s/^[[:space:]]*//;p;q;}' ./project.yml`
BUILD_FOLDER="Build/Releases"
BUILD_PATH="$BUILD_FOLDER/$APP_NAME $VERSION_NUMBER.dmg"

echo "🤐 Zipping ..."

zip "$BUILD_FOLDER/Keyboard Cowboy.zip" "$BUILD_PATH"
