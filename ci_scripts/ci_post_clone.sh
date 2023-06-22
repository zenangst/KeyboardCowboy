#!/bin/sh
brew install --cask tuist
touch .ci_env
echo "APP_NAME=Keyboard Cowboy" >> .env
echo "APP_SCHEME=Keyboard-Cowboy" >> .env
echo "APP_BUNDLE_IDENTIFIER=com.zenangst.Keyboard-Cowboy" >> .env
echo "TEAM_ID=XXXXXXXXXX" >> .env
source .env
tuist fetch
tuist generate
