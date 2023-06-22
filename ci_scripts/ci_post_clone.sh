#!/bin/sh
brew install tuist
touch .ci_env
echo "APP_NAME=Keyboard Cowboy" >> .ci_env
echo "APP_SCHEME=Keyboard-Cowboy" >> .ci_env
echo "APP_BUNDLE_IDENTIFIER=com.zenangst.Keyboard-Cowboy" >> .ci_env
echo "TEAM_ID=XXXXXXXXXX" >> .ci_env
source .ci_env
tuist fetch
tuist generate
