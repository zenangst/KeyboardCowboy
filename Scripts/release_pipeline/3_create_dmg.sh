#!/bin/zsh

source .env > /dev/null 2>&1

# Create a .dmg
create-dmg "Build/Releases/$APP_NAME.app" \
  --overwrite \
  --dmg-title="$APP_NAME" \
  Build/Releases
