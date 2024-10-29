#!/bin/zsh

source .env

BUILD_NUMBER=`agvtool what-version | sed -n 2p | xargs`
VERSION_NUMBER=`sed -n '/MARKETING_VERSION/s/.*: *"\([0-9.]*\)".*/\1/p' ./Project.swift`
FILENAME="$APP_SCHEME.$VERSION_NUMBER.$BUILD_NUMBER.xcarchive"
PLIST_CONTENTS=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"\n "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n
<plist version="1.0">\n
<dict>\n
</dict>\n
</plist>
EOF
)

echo "🚚 Exporting"

echo $PLIST_CONTENTS > exportOptions.plist
plutil -insert method -string "developer-id" exportOptions.plist
plutil -insert teamID -string  $TEAM_ID exportOptions.plist

# Build and archive a new version
xcodebuild \
  -archivePath ./Build/$FILENAME \
  -exportArchive \
  -exportPath 'Build/Releases'\
  -exportOptionsPlist exportOptions.plist \
  | xcbeautify
