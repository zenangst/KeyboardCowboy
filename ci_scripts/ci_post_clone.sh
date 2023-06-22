#!/bin/sh
curl -Ls https://install.tuist.io | bash
touch ../.env
echo "APP_NAME=Keyboard Cowboy" >> ../.env
echo "APP_SCHEME=Keyboard-Cowboy" >> ../.env
echo "APP_BUNDLE_IDENTIFIER=com.zenangst.Keyboard-Cowboy" >> ../.env
echo "TEAM_ID=XXXXXXXXXX" >> .env
source ../.env
tuist fetch --path ../
tuist generate -n --path ../
