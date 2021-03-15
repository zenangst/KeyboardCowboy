#!/bin/zsh

# Fetch external dependencies
echo "🗃 Resolving dependencies"
xcodebuild -resolvePackageDependencies
