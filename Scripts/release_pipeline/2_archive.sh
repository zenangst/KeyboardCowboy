#!/bin/zsh

source .env

BUILD_NUMBER=`agvtool what-version | sed -n 2p | xargs`
VERSION_NUMBER=`sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION: //;s/;//;s/^[[:space:]]*//;p;q;}' ./project.yml`
FILENAME="$APP_SCHEME.$VERSION_NUMBER.$BUILD_NUMBER"

echo "🛠 Archiving"

# Build and archive a new version
xcodebuild \
 -config Release\
 -scheme $APP_SCHEME \
 -archivePath ./Build/$FILENAME \
 archive \
 | xcpretty
