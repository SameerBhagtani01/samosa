#!/bin/bash
REPO_URL="https://github.com/SameerBhagtani01/samosa.git"
INSTALL_DIR="/tmp/samosa"

# Trap to ensure cleanup runs even if the script fails unexpectedly
trap 'echo "Attempting cleanup of $INSTALL_DIR..." && rm -rf "$INSTALL_DIR"' EXIT

echo "Checking for Git..."
if ! command -v git &> /dev/null; then
    echo "Git not found. Attempting to install via pacman..."
    # Attempt to install git just in case the base Arch install didn't include it
    # Use 'set +e' temporarily so the script doesn't exit immediately if pacman fails here
    set +e
    sudo pacman -Sy --noconfirm git
    PACMAN_STATUS=$?
    set -e
    if [ $PACMAN_STATUS -ne 0 ]; then
        echo "Failed to install git. Aborting."
        exit 1
    fi
fi

echo "Cloning setup utility to $INSTALL_DIR..."
# Ensure any previous clone is gone and clone the new one
rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR" || { echo "Failed to clone repository. Aborting."; exit 1; }

echo "Executing the main installation script..."
cd "$INSTALL_DIR"
sudo sh main.sh

echo "Installing essential packages via Yay"
yay -S --needed visual-studio-code-bin brave-bin ttf-cascadia-code-nerd walker elephant-calc elephant-clipboard elephant-symbols

echo "Enabling required services"
elephant service enable || echo "Warning: Elephant service enable command failed."

echo ""
echo "############################################################"
echo "Cleaning up temporary files."
echo "############################################################"
rm -rf "$INSTALL_DIR"

echo -e "\n\n***************************************"
echo "*** Setup Complete!                   ***"
echo "*** Reboot your system and enjoy Samosa! ***"
echo "***************************************"