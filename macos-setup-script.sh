#!/usr/bin/env bash
# Setup script for setting up a new macos machine

echo "Starting setup"

# install xcode CLI
xcode-select —-install

# Check for Homebrew to be present, install if it's missing
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

# tap tap tap
brew tap elastic/tap
brew tap github/gh
brew tap heroku/brew
brew tap homebrew/bundle
brew tap homebrew/cask
brew tap homebrew/cask-fonts
brew tap homebrew/core
brew tap homebrew/services
brew tap neovim/neovim
brew tap rockymadden/rockymadden
brew tap universal-ctags/universal-ctags


# restore from Brewfile
brew tap Homebrew/bundle
brew bundle
