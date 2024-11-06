#!/bin/zsh

source .env > /dev/null 2>&1

echo "✨ Update appcast.xml"
Sparkle/./generate_appcast -o appcast.xml Build/Releases/
