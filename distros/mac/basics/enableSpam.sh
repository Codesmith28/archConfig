#!/bin/bash
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write com.apple.dock autohide-delay -float 0; killall Dock
defaults write com.apple.dock autohide-time-modifier -float 0.15; killall Dock
