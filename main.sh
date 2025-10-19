#!/bin/bash
set -euo pipefail # Exit on error, unset variable, and pipe failure

REPO_ROOT=$(dirname "$(readlink -f "$0")")

# Define path variables for clarity
PACKAGE_LISTS="$REPO_ROOT/package-lists"
OTHER_FILES="$REPO_ROOT/other"
SYSTEM_CONFIGS="$REPO_ROOT/dotfiles/system_configs"
USER_CONFIGS="$REPO_ROOT/dotfiles/user_configs"

# --- Initial Checks and Setup ---

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run with sudo (e.g., sudo ./install.sh)."
    exit 1
fi

# Determine the non-root user that called sudo
if [ -z "${SUDO_USER:-}" ]; then
    echo "Error: SUDO_USER variable is not set. Cannot determine target user."
    exit 1
fi

USER="$SUDO_USER"
USER_HOME="/home/$USER"
echo "Starting automated Arch setup for user: $USER"

# --- Function Definitions ---

# Install packages using the list file
install_pacman_packages() {
    echo -e "\n--- Installing PACMAN Packages ---"
    local packages_file="$PACKAGE_LISTS/pacman_packages.txt"
    if [ -f "$packages_file" ]; then
        local packages=($(cat "$packages_file"))
        pacman -S --noconfirm --needed "${packages[@]}"
    else
        echo "Warning: $packages_file not found. Skipping pacman installs."
    fi
}

# Install AUR packages using the list file
install_aur_packages() {
    echo -e "\n--- Installing AUR Packages via Yay ---"
    local packages_file="$PACKAGE_LISTS/aur_packages.txt"
    if [ -f "$packages_file" ]; then
        if ! sudo -u "$USER" command -v yay &> /dev/null; then
            echo "Error: yay is not installed or not in \$PATH for $USER. Skipping AUR installs."
            return
        fi
        sudo -u "$USER" yay -S --noconfirm --needed $(cat "$packages_file")
    else
        echo "Warning: $packages_file not found. Skipping AUR installs."
    fi
}

# Install Flatpak apps using the list file
install_flatpak_apps() {
    echo -e "\n--- Installing Flatpak Applications ---"
    local apps_file="$PACKAGE_LISTS/flatpak_apps.txt"
    if [ -f "$apps_file" ]; then
        echo "Enabling Flathub remote..."
        sudo -u "$USER" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        
        local flatpak_apps=$(cat "$apps_file" | tr '\n' ' ')
        echo "Installing apps: $flatpak_apps"
        sudo -u "$USER" flatpak install flathub --noninteractive $flatpak_apps
    else
        echo "Warning: $apps_file not found. Skipping Flatpak installs."
    fi
}


# --- Execution Steps ---

# Enable Multilib and Sync
echo -e "\n--- Enabling Multilib Repository ---"
pacman -Sy --noconfirm # Initial sync
if [ -f "$SYSTEM_CONFIGS/etc-pacman.conf" ]; then
    cp "$SYSTEM_CONFIGS/etc-pacman.conf" /etc/pacman.conf
    echo "Using custom pacman.conf. Syncing repositories..."
    pacman -Sy --noconfirm # Sync after enabling multilib
else
    echo "Warning: Custom etc-pacman.conf not found. Attempting sed edit for multilib."
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    pacman -Sy --noconfirm
fi

# Install Yay (AUR Helper)
echo -e "\n--- Installing Yay ---"
pacman -S --noconfirm --needed git base-devel
if ! sudo -u "$USER" command -v yay &> /dev/null; then
    sudo -u "$USER" git clone https://aur.archlinux.org/yay.git /tmp/yay
    chown -R "$USER:$USER" /tmp/yay
    sudo -u "$USER" sh -c "cd /tmp/yay && makepkg -si --noconfirm"
    rm -rf /tmp/yay
else
    echo "Yay is already installed."
fi

# Install Core and Required Packages
install_pacman_packages
install_aur_packages

# Install Brave Browser
echo -e "\n--- Installing Brave Browser ---"
curl -fsS https://dl.brave.com/install.sh | sh

# Enable Ly Display Manager
echo -e "\n--- Enabling Ly Service ---"
systemctl enable ly.service

# Add User to Groups
echo -e "\n--- Adding $USER to necessary groups (video, audio, input) ---"
usermod -aG video,audio,input "$USER"

# System Configuration Edits
echo -e "\n--- Copying System Configuration Files to /etc/ ---"
# Copy files from system_configs to /etc/
cp "$SYSTEM_CONFIGS/etc-vconsole.conf" /etc/vconsole.conf
cp "$SYSTEM_CONFIGS/etc-systemd-logind.conf" /etc/systemd/logind.conf
cp "$SYSTEM_CONFIGS/etc-ly-config.ini" /etc/ly/config.ini

# Copy all User Configs
echo -e "\n--- Copying User Configs (Dotfiles) ---"
# Copy .config and .local/bin
sudo -u "$USER" rsync -a "$USER_CONFIGS/." "$USER_HOME/"

# Place wallpaper in ~/Pictures
echo -e "--- Copying Wallpaper to $USER_HOME/Pictures ---"
sudo -u "$USER" mkdir -p "$USER_HOME/Pictures"
cp "$OTHER_FILES/wallpaper.jpg" "$USER_HOME/Pictures/wallpaper.jpg"

# Create Qalculate Config
echo -e "--- Creating Qalculate configuration files ---"
sudo -u "$USER" mkdir -p "$USER_HOME/.config/qalculate"
sudo -u "$USER" touch "$USER_HOME/.config/qalculate/qalc.cfg"

# Append to bashrc
echo -e "\n--- Appending content to ~/.bashrc ---"
cat "$OTHER_FILES/bashrc_append.txt" >> "$USER_HOME/.bashrc"

# Fix ownership for all copied user files
echo -e "--- Fixing ownership of user files ---"
chown -R "$USER:$USER" "$USER_HOME/.config" "$USER_HOME/.local" "$USER_HOME/.bashrc" "$USER_HOME/Pictures"

# Make power-menu.sh executable
echo -e "--- Setting Permissions for power-menu.sh ---"
chmod +x "$USER_HOME/.local/bin/power-menu.sh"

# Enable Elephant services
echo -e "\n--- Enabling Elephant Services ---"
sudo -u "$USER" elephant service enable || echo "Warning: Elephant service enable command failed."

# Flatpak Applications
install_flatpak_apps

# GRUB Configuration
echo -e "\n--- Updating GRUB Configuration ---"
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\n\n***************************************"
echo "*** Setup Complete!                   ***"
echo "*** Please reboot the system to start ***"
echo "*** Hyprland and Ly Display Manager.  ***"
echo "***************************************"