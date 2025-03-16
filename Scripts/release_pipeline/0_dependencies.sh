#!/bin/zsh

# Fetch external dependencies
echo "🗃 Resolving dependencies"
tuist generate
tuist build 
