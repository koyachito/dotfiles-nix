#!/usr/bin/env bash
set -euo pipefail
# Fedora Sway Spin 44. Explicit phases; never run everything automatically.
# shellcheck source=/dev/null
source /etc/os-release
[[ "$ID" == fedora ]] || { echo 'Fedora only' >&2; exit 1; }
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
case "${1:-}" in
  ime)
    sudo dnf install fcitx5 fcitx5-mozc fcitx5-configtool fcitx5-gtk fcitx5-qt \
      glibc-langpack-ja
    ;;
  input)
    sudo install -m 0644 "$repo/othersettings/uinput.conf" /etc/modules-load.d/dotfiles-uinput.conf
    sudo install -m 0644 "$repo/fedora/99-dotfiles-uinput.rules" /etc/udev/rules.d/99-dotfiles-uinput.rules
    sudo usermod -aG input "$(id -un)"
    sudo modprobe uinput
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=misc --sysname-match=uinput
    sudo restorecon -v /dev/uinput
    echo 'Log out and back in before testing xremap. Input group can read all input devices.'
    ;;
  *) echo 'Usage: bash fedora/bootstrap.sh {ime|input}' >&2; exit 2 ;;
esac
