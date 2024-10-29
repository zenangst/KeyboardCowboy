#!/bin/zsh

source .env

BUILD_NUMBER=`agvtool what-version | sed -n 2p | xargs`
VERSION_NUMBER=`sed -n '/MARKETING_VERSION/s/.*: *"\([0-9.]*\)".*/\1/p' ./Project.swift`
FILENAME="$APP_SCHEME.$VERSION_NUMBER.$BUILD_NUMBER"

echo "🛠 Archiving"


# Build and archive a new version
xcodebuild \
 -workspace Keyboard\ Cowboy.xcworkspace\
 -config Release\
 -scheme $APP_SCHEME \
 -archivePath ./Build/$FILENAME \
 archive \
 | xcbeautify
