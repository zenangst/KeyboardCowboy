#!/bin/sh
brew install tuist
touch .env
echo "APP_NAME=Keyboard Cowboy" >> .env
echo "APP_SCHEME=Keyboard-Cowboy" >> .env
echo "APP_BUNDLE_IDENTIFIER=com.zenangst.Keyboard-Cowboy" >> .env
echo "TEAM_ID=XXXXXXXXXX" >> .env
tuist fetch
tuist generate
