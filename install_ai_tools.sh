#!/usr/bin/env bash

set -e

echo "🤖 Installing AI CLI Tools"
echo "========================="

# Ensure Node.js and npm are installed
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "📦 Node.js/npm not found. Installing..."
    ./install_node.sh
fi

# Install AI CLI tools
echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

echo "📦 Installing Qwen Code..."
npm install -g @qwen-code/qwen-code

echo "📦 Installing Codex..."
npm install -g @openai/codex

echo "📦 Installing Gemini CLI..."
npm install -g @google/gemini-cli

# Install GitHub CLI and Copilot extension
if ! command -v gh &> /dev/null; then
    echo "📦 GitHub CLI not found. Installing..."
    ./install_gh.sh
fi

echo "🔧 Setting up GitHub Copilot extension..."
if ! gh auth status &> /dev/null; then
    echo "🔑 Please authenticate with GitHub:"
    gh auth login
fi

echo "📦 Installing GitHub Copilot extension..."
gh extension install github/gh-copilot

echo "🎉 AI tools installation complete!"
echo ""
echo "Installed tools:"
echo "  ✅ Claude Code"
echo "  ✅ Qwen Code"
echo "  ✅ Gemini CLI"
echo "  ✅ GitHub Copilot CLI extension"
echo ""
echo "To get started:"
echo "  • Claude Code: Run 'claude'"
echo "  • Qwen Code: Run 'qwen'"
echo "  • Gemini CLI: Run 'gemini'"
echo "  • GitHub Copilot: Run 'gh copilot'"
