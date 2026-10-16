#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=/dev/null
source /etc/os-release
[[ "$ID" == arch ]] || { echo 'Arch only. Fedora: see docs/fedora.md' >&2; exit 1; }

sudo pacman -S --needed \
	base \
	base-devel \
	bat \
	bitwarden \
	brightnessctl \
	btop \
	btrfs-progs \
	clang \
	cmake \
	eza \
	fcitx5 \
	fcitx5-configtool \
	fcitx5-gtk \
	fcitx5-mozc \
	fd \
	firefox \
	fuzzel \
	fzf \
	git \
	grim \
	intel-ucode \
	jq \
	kdeconnect \
	kitty \
	lazygit \
	less \
	libnotify \
	libinput-tools \
	linux \
	linux-firmware \
	mako \
	man-db \
	man-pages \
	neovim \
	networkmanager \
	nodejs \
	noto-fonts-cjk \
	noto-fonts-emoji \
	npm \
	obsidian \
	openssh \
	pacman-contrib \
	pdfgrep \
	pipewire-pulse \
	playerctl \
	python-pipx \
	ripgrep \
	rust \
	shellcheck \
	shfmt \
	slurp \
	sddm \
	tesseract-data-jpn \
	thunderbird \
	tldr \
	tree \
	typescript \
	ufw \
	unzip \
	waybar \
	wget \
	wl-clipboard \
	wlsunset \
	yazi \
	zathura \
	zathura-pdf-mupdf \
	zip \
	zoxide \
	xdg-desktop-portal \
	xdg-desktop-portal-gtk

cargo install --locked xremap zellij

DOTFILES="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
DOTFILES_CONFIG="$DOTFILES/config"
SETTINGS="$DOTFILES/othersettings"

mkdir -p "$HOME/.local/bin"
mkdir -p "$CONFIG_DIR"

for dir in \
	kitty \
	mako \
	nvim \
	pandoc \
	systemd \
	xremap \
	yazi \
	zathura \
	waybar
do
	ln -sfn "$DOTFILES_CONFIG/$dir" "$CONFIG_DIR/$dir"
done

ln -sfn "$SETTINGS/.profile" "$HOME/.profile"
ln -sfn "$SETTINGS/.bashrc" "$HOME/.bashrc"

mkdir -p "$HOME/Pictures/ScreenShots"

sudo cp "$SETTINGS/uinput.conf" /etc/modules-load.d/
sudo cp "$SETTINGS/99-uinput.rules" /etc/udev/rules.d/

sudo usermod -aG input "$USER"

sudo modprobe uinput
sudo udevadm control --reload-rules
sudo udevadm trigger

sudo systemctl enable sddm
sudo systemctl enable --now NetworkManager

systemctl --user daemon-reload
systemctl --user enable --now xremap
systemctl --user enable --now kdeconnect-indicator

bootctl update
sudo mkinitcpio -P

fc-cache -fv

echo "Common installation completed."
echo "Please reboot to apply the input group change."
