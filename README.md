# 🥟 SAMOSA: My Automated Arch Linux Utility 🌶️

Welcome to the **SAMOSA** setup! This repository contains all my configuration files and a single script to automatically bootstrap a minimal Arch Linux installation into my complete, customized Wayland desktop environment based on **Hyprland**.

## 🚀 One-Command Install

To get the complete SAMOSA experience on a fresh, minimal Arch install, just run this command (it handles installing Git, cloning the repo, and running the setup script with `sudo`):

```bash
curl -L https://raw.githubusercontent.com/SameerBhagtani01/samosa/refs/heads/main/install.sh | sh
```

---

## ⚠️ Notes & Requirements

-   Operating System: This utility is specifically designed for a minimal base installation of Arch Linux.
-   Internet Connection: Required throughout the installation process.
-   User Account: The script requires running with sudo and assumes a non-root user account exists to apply the configs to (it uses the $SUDO_USER variable).
