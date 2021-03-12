#!/bin/zsh

source .env

# Create a .dmg
create-dmg "Build/Releases/$APP_NAME.app" \
  --overwrite \
  --dmg-title="$APP_NAME" \
  Build/Releases
