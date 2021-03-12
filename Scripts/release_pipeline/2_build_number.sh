#!/bin/zsh

CURRENT_VERSION=`agvtool what-version | sed -n 3p | xargs`
NEW_VERSION=`expr $CURRENT_VERSION + 1`

echo "💪 New build: $NEW_VERSION"

# Bump the current build number
agvtool new-version $NEW_VERSION
