#!/bin/bash

echo "[GUYS SETUP] Initializing..."
sleep 1

echo "[GUYS SETUP] Updating apt..."
sudo apt update

echo "[GUYS SETUP] Changing default shell to Zsh..."
chsh -s $(which zsh)

echo "[GUYS SETUP] Installing OhMyZsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
