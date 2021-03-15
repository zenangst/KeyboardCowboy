#!/bin/zsh
source .env
export TEAM_ID=$TEAM_ID
xcodegen
sleep 0.5
#open "Keyboard-Cowboy.xcodeproj"
