#!/bin/bash

# Install my ZSH Theme
ln -s $(pwd)/jim.zsh-theme ~/.oh-my-zsh/themes/jim.zsh-theme
rm ~/.zshrc
ln -s $(pwd)/.zshrc ~/.zshrc

# Install Oh My Zsh
curl -fsSLO https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
