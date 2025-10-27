#!/bin/bash

echo "[GUYS SETUP] Initializing..."
sleep 1

echo "[GUYS SETUP] Updating apt..."
sudo apt update

echo "[GUYS SETUP] Installing Zsh..."
sudo apt install zsh -y

echo "[GUYS SETUP] Changing default shell to Zsh..."
chsh -s $(which zsh)

echo "[GUYS SETUP] Installing OhMyZsh..."
RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed '/\s*env\s\s*zsh\s*/d')"

echo "[GUYS SETUP] Installing build-essential..."
sudo apt install build-essential -y

echo "[GUYS SETUP] Installing fzf..."
sudo apt install fzf -y

echo "[GUYS SETUP] Installing Neovim..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
