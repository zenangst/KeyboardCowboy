#!/bin/zsh

# Fetch external dependencies
echo "🗃 Resolving dependencies"
tuist install
tuist generate -n
