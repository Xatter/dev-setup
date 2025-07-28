#!/bin/bash

# Check for nvm and install if not found
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  . "$HOME/.nvm/nvm.sh"
else
  echo "nvm not found, installing..."
  ./install_nvm.sh
  . "$HOME/.nvm/nvm.sh"
fi

# Install node and npm
nvm install node
nvm use node

# Check for node and npm again
if ! command -v node &> /dev/null
then
    echo "node could not be found"
    exit
fi

if ! command -v npm &> /dev/null
then
    echo "npm could not be found"
    exit
fi

npm install -g @anthropic-ai/claude-code
npm install -g @qwen-code/qwen-code
npm install -g @google/gemini-cli
