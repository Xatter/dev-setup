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

# Setup Claude configuration
if [ -d "$(pwd)/dotfiles/claude" ]; then
    echo "Setting up Claude configuration..."
    $(pwd)/dotfiles/claude/setup.sh
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s $(which zsh)
    echo "Default shell changed to zsh. Please log out and log back in for changes to take effect."
fi
