#!/bin/bash

# hyprland: This is the Hyprland compositor
# kitty: This is the default terminal
# waybar: Waybar now has hyprland support
# swaybg: This is used to set a desktop background image
# swaylock-effects: This allows for the locking of the desktop its a fork that adds some editional visual effects
# wofi: This is an application launcher menu
# wlogout: This is a logout menu that allows for shutdown, reboot and sleep
# mako: This is a graphical notification daemon
# thunar: This is a graphical file manager
# ttf-jetbrains-mono-nerd: Som nerd fonts for icons and overall look
# noto-fonts-emoji: fonts needed by the weather script in the top bar
# polkit-gnome: needed to get superuser access on some graphical appliaction
# python-requests: needed for the weather module script to execute
# starship: allows to customize the shell prompt
# swappy: This is a screenshot editor tool
# grim: This is a screenshot tool it grabs images from a Wayland compositor
# slurp: This helps with screenshots, it selects a region in a Wayland compositor
# pamixer: This helps with audio settings such as volume
# brightnessctl: used to control monitor bright level
# gvfs: adds missing functionality to thunar such as automount usb drives
# bluez: the bluetooth service
# bluez-utils: command line utilities to interact with bluettoth devices
# lxappearance: used to set GTK theme
# xfce4-settings: set of tools for xfce, needed to set GTK theme
# dracula-gtk-theme: the Dracula theme, it fits the overall look and feel
# dracula-icons-git" set of icons to go with the Dracula theme
# xdg-desktop-portal-hyprland: xdg-desktop-portal backend for hyprland

#### Check for yay ####
ISYAY=/sbin/yay
if [ -f "$ISYAY" ]; then 
    echo -e "yay was located, moving on.\n"
    yay -Suy
else 
    echo -e "yay was not located, please install yay. Exiting script.\n"
    exit 
fi

### Install all of the above pacakges ####
read -n1 -rep '[?] Would you like to install the packages [HYPRLAND] ? (y,n)' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    yay -S --noconfirm hyprland kitty waybar \
    swaybg swaylock-effects wofi wlogout mako thunar \
    ttf-jetbrains-mono-nerd noto-fonts-emoji \
    polkit-gnome python-requests starship \
    swappy grim slurp pamixer brightnessctl gvfs \
    bluez bluez-utils lxappearance xfce4-settings \
    dracula-gtk-theme dracula-icons-git xdg-desktop-portal-hyprland
    echo -e "[!] Starting the Bluetooth Service...\n"
    sudo systemctl enable --now bluetooth.service
    sleep 2
    echo -e "[!] Cleaning out conflicting xdg portals...\n"
    yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk
fi

read -n1 -rep '[?] Would you like to copy config files for Hyprland? (y,n)' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "Copying config files...\n"
    cp -R config/hypr ~/.config/
    cp -R config/kitty ~/.config/
    cp -R config/mako ~/.config/
    cp -R config/waybar ~/.config/
    cp -R config/swaylock ~/.config/
    cp -R config/wofi ~/.config/
    cp -R config/swappy ~/.config/
    chmod +x ~/.config/hypr/xdg-portal-hyprland
    chmod +x ~/.config/waybar/scripts/waybar-wttr.py
    chmod +x ~/.config/waybar/Waybar-3.0/scripts/window-name.sh
    chmod +x ~/.config/waybar/Waybar-3.0/scripts/title/icon_check.sh
fi

read -n1 -rep '[?] Would you like to copy the vim config files? (y,n)' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "Copying config files...\n"
    cp -R vim/vimrc ~/.vimrc
fi

read -n1 -rep '[?] Would you like to copy the zsh config files? (y,n)' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "Copying config files...\n"
    cp -R zsh/zshrc ~/.zshrc
fi

read -n1 -rep '[?] Would you to install additional packages? (y,n)' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "Installing packages...\n"
    pacman -S sof-firmware pulseaudio
fi

### Script is done ###
echo -e "[!] Script had completed.\n"
echo -e "[!] You can start Hyprland by typing Hyprland (note the capital H).\n"
read -n1 -rep '[?] Would you like to start Hyprland now? (y,n)' HYP
if [[ $HYP == "Y" || $HYP == "y" ]]; then
    exec Hyprland
else
    exit
fi
