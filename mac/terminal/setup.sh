#!/bin/bash

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Enable VIM keybindings for command line in zsh
echo "bindkey -v" >> ~/.zshrc

# Install my ZSH Theme
ln -s ./jim.zsh-theme ~/.oh-my-zsh/themes/jim.zsh-theme
cat ~/.zshrc | sed 's/ZSH_THEME="robbyrussell"/ZSH_THEME="jim"/' > ~/.zshrc

