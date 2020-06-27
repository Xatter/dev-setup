#!/bin/bash

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install my ZSH Theme
ln -s $(pwd)/jim.zsh-theme ~/.oh-my-zsh/themes/jim.zsh-theme
rm ~/.zshrc
ln -s $(pwd)/.zshrc ~/.zshrc

