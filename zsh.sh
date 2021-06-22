#!/bin/bash

if ! command -v zsh &> /dev/null
then
	if [[ $OSTYPE == "darwin"* ]]; then
		brew install zsh
	else
		sudo apt install -y zsh
	fi
fi

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install my ZSH Theme
ln -s $(pwd)/jim.zsh-theme ~/.oh-my-zsh/themes/jim.zsh-theme
rm ~/.zshrc
ln -s $(pwd)/.zshrc ~/.zshrc

# Setup VIM
ln -s $(pwd)/.vimrc ~/.vimrc
