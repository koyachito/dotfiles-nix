{ pkgs }:
let qtApp = import ./qt-app.nix { inherit pkgs; };
in
with pkgs; [
  bat bitwarden-desktop btop clang cmake eza fd firefox fuzzel fzf git
  grim jq (qtApp kdePackages.kdeconnect-kde) kitty lazygit less libnotify mako
  neovim nodejs noto-fonts-cjk-sans noto-fonts-color-emoji obsidian
  openssh pandoc pavucontrol pdfgrep playerctl pipx ripgrep rustc cargo
  shellcheck shfmt slurp (tesseract.override { enableLanguages = [ "eng" "jpn" ]; })
  thunderbird tldr tree typst
  typescript unzip waybar wget wl-clipboard wlsunset
  yazi zathura zellij zip zoxide xremap nerd-fonts.jetbrains-mono
]
