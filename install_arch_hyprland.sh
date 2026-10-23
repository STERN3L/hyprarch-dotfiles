#!/usr/bin/env bash
#
# my_arch — Hyprland desktop installer for Arch Linux
# https://github.com/STERN3L/my_arch
#
# Usage: ./install_arch_hyprland.sh [-y|--yes] [-h|--help]
#   -y, --yes   answer "yes" to every prompt (non-interactive)
#   -h, --help  show this help
#
# Every existing configuration that would be overwritten is first moved to
# ~/.config-backup-<timestamp>/.

set -euo pipefail

REPO_URL="https://github.com/STERN3L/my_arch.git"
ASSUME_YES=false

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------

# Compositor, session and portals
PKG_CORE=(
  hyprland hypridle hyprlock
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  polkit-gnome
)

# Bar, launcher, notifications, wallpaper, terminals, file manager
PKG_DESKTOP=(
  waybar wofi mako libnotify swaybg
  kitty terminator
  thunar gvfs
)

# Audio, media, brightness, network, Bluetooth, power
PKG_SYSTEM=(
  pipewire pipewire-pulse wireplumber pavucontrol playerctl
  brightnessctl
  networkmanager
  bluez bluez-utils
  power-profiles-daemon
)

# Screenshots, clipboard and tools used by the Waybar modules
PKG_TOOLS=(
  grim slurp swappy
  wl-clipboard cliphist
  jq pacman-contrib xorg-xrdb htop filelight
)

# Fonts and themes
PKG_THEME=(
  ttf-jetbrains-mono-nerd noto-fonts-emoji
  papirus-icon-theme
)

# AUR packages
PKG_AUR=(
  wlogout
  blueberry
  catppuccin-cursors-macchiato
)

# Configuration directories copied from config/ to ~/.config/
CONFIG_DIRS=(hypr waybar wlogout kitty mako wofi swappy terminator gtk-3.0)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m::\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m::\033[0m %s\n' "$*" >&2; exit 1; }

# ask "Question?" -> returns 0 when the answer is yes
ask() {
  $ASSUME_YES && return 0
  local reply
  read -r -n1 -p "$(printf '\033[1;35m[?]\033[0m %s [y/N] ' "$1")" reply
  echo
  [[ $reply == [yY] ]]
}

usage() {
  cat <<'EOF'
my_arch — Hyprland desktop installer for Arch Linux

Usage: ./install_arch_hyprland.sh [-y|--yes] [-h|--help]
  -y, --yes   answer "yes" to every prompt (non-interactive)
  -h, --help  show this help

Existing configuration files are moved to ~/.config-backup-<timestamp>/ before being replaced.
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

preflight() {
  [[ -f /etc/arch-release ]] || die "This script only supports Arch Linux."
  [[ $EUID -ne 0 ]] || die "Run this script as a regular user, not as root (sudo is used when needed)."
  command -v sudo >/dev/null || die "sudo is required."
}

# When run through curl (bash <(curl ...)), the configuration files are not next
# to the script: clone the repository and re-run the installer from the clone.
ensure_repo() {
  local script_dir
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)

  if [[ -n $script_dir && -d $script_dir/config/hypr ]]; then
    REPO_DIR=$script_dir
    return
  fi

  info "Repository files not found locally, cloning $REPO_URL"
  sudo pacman -S --needed --noconfirm git
  local tmp
  tmp=$(mktemp -d)
  git clone --depth 1 "$REPO_URL" "$tmp/my_arch"
  exec bash "$tmp/my_arch/install_arch_hyprland.sh" "$@"
}

ensure_yay() {
  if command -v yay >/dev/null; then
    ok "yay found"
    return
  fi
  ask "yay (AUR helper) is not installed. Install it now?" ||
    die "yay is required for the AUR packages (${PKG_AUR[*]})."

  sudo pacman -S --needed --noconfirm git base-devel
  local tmp
  tmp=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  ok "yay installed"
}

install_packages() {
  ask "Install the Hyprland desktop packages?" || return 0

  info "Updating the system"
  sudo pacman -Syu --noconfirm

  info "Installing official packages"
  sudo pacman -S --needed --noconfirm \
    "${PKG_CORE[@]}" "${PKG_DESKTOP[@]}" "${PKG_SYSTEM[@]}" "${PKG_TOOLS[@]}" "${PKG_THEME[@]}"

  info "Installing AUR packages"
  yay -S --needed --noconfirm "${PKG_AUR[@]}"

  ok "Packages installed"
}

enable_services() {
  ask "Enable system services (NetworkManager, Bluetooth, power profiles)?" || return 0
  sudo systemctl enable --now NetworkManager.service
  sudo systemctl enable --now bluetooth.service
  sudo systemctl enable --now power-profiles-daemon.service
  ok "Services enabled"
}

# backup_path <path>: move an existing file or directory into the backup folder
backup_path() {
  local target=$1
  [[ -e $target || -L $target ]] || return 0
  mkdir -p "$BACKUP_DIR"
  mv "$target" "$BACKUP_DIR/"
  warn "Backed up $target -> $BACKUP_DIR/"
}

copy_configs() {
  ask "Copy the Hyprland configuration files to ~/.config?" || return 0

  mkdir -p "$HOME/.config"
  for dir in "${CONFIG_DIRS[@]}"; do
    backup_path "$HOME/.config/$dir"
    cp -R "$REPO_DIR/config/$dir" "$HOME/.config/"
  done

  # systemd user units are merged into the existing directory
  mkdir -p "$HOME/.config/systemd/user"
  cp "$REPO_DIR"/config/systemd/user/battery-notify.* "$HOME/.config/systemd/user/"

  chmod +x "$HOME/.config/hypr/xdg-portal-hyprland" \
           "$HOME"/.config/hypr/scripts/*.sh \
           "$HOME"/.config/waybar/Waybar-3.0/scripts/*.sh

  if systemctl --user daemon-reload 2>/dev/null; then
    systemctl --user enable battery-notify.timer
  else
    warn "No systemd user session: run 'systemctl --user enable --now battery-notify.timer' after logging in."
  fi

  # GTK 4 / libadwaita applications read these settings from dconf
  if command -v gsettings >/dev/null; then
    {
      gsettings set org.gnome.desktop.interface color-scheme prefer-dark
      gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
      gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
      gsettings set org.gnome.desktop.interface cursor-theme catppuccin-macchiato-dark-cursors
      gsettings set org.gnome.desktop.interface cursor-size 24
    } 2>/dev/null || warn "Could not apply GTK settings with gsettings (no D-Bus session?)."
  fi

  ok "Configuration files copied"
}

install_zsh() {
  ask "Install the zsh configuration (oh-my-zsh + zsh-autosuggestions)?" || return 0

  sudo pacman -S --needed --noconfirm zsh git curl

  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    info "Installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  local plugin_dir=$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  [[ -d $plugin_dir ]] || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"

  backup_path "$HOME/.zshrc"
  cp "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"

  if [[ ${SHELL:-} != */zsh ]] && ask "Make zsh your default shell?"; then
    chsh -s "$(command -v zsh)"
  fi
  ok "zsh configured"
}

install_vim() {
  ask "Install the vim configuration?" || return 0
  sudo pacman -S --needed --noconfirm vim
  backup_path "$HOME/.vimrc"
  cp "$REPO_DIR/vim/vimrc" "$HOME/.vimrc"
  ok "vim configured"
}

install_firmware() {
  ask "Install Sound Open Firmware (required for audio on most recent laptops)?" || return 0
  sudo pacman -S --needed --noconfirm sof-firmware
  ok "sof-firmware installed"
}

finish() {
  echo
  ok "Installation complete."
  [[ -d $BACKUP_DIR ]] && info "Previous configuration saved in $BACKUP_DIR"
  info "Log out and start Hyprland (type 'Hyprland' from a TTY, or select it in your display manager)."
  if [[ -z ${WAYLAND_DISPLAY:-} ]] && ask "Start Hyprland now?"; then
    exec Hyprland
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  for arg in "$@"; do
    case $arg in
      -y|--yes) ASSUME_YES=true ;;
      -h|--help) usage ;;
      *) die "Unknown option: $arg (see --help)" ;;
    esac
  done

  BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

  preflight
  ensure_repo "$@"
  ensure_yay
  install_packages
  enable_services
  copy_configs
  install_zsh
  install_vim
  install_firmware
  finish
}

main "$@"
