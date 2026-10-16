#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=/dev/null
source /etc/os-release
[[ "$ID" == arch ]] || { echo 'Arch only. Fedora: see docs/fedora.md' >&2; exit 1; }

DOTFILES="$HOME/dotfiles"
SCRIPTS="$DOTFILES/scripts"

sudo pacman -S --needed \
	sway \
	swaybg \
	swayidle \
	swaylock \
	xdg-desktop-portal-wlr

ln -sfn "$DOTFILES/config/sway" "$HOME/.config/sway"
ln -sfn "$SCRIPTS/powermenu-sway" "$HOME/.local/bin/powermenu"


for cmd in \
	sway \
	swaybg \
	swayidle \
	swaylock
do
	command -v "$cmd"
done

echo "Sway installation completed."
