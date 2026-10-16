{ config, lib, pkgs, username, homeDirectory, desktop, ... }:
{
  home = {
    inherit username homeDirectory;
    stateVersion = "26.05";
    packages = import ./packages.nix { inherit pkgs; };
    sessionVariables = { EDITOR = "nvim"; VISUAL = "nvim"; };
    sessionPath = [ "$HOME/.local/bin" "$HOME/.cargo/bin" ];
    file = builtins.listToAttrs (map (name: {
      name = ".local/bin/${name}";
      value = { source = ../scripts + "/${name}"; executable = true; };
    }) [ "battery-warning" "kde-send" "count-mouse" "benchmark.sh" ]) // {
      ".local/bin/powermenu" = { source = ../scripts/powermenu-sway; executable = true; };
    };
    activation.screenshotDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg "${homeDirectory}/Pictures/ScreenShots"}
    '';
    # Fcitx writes these files. Seed new installs without overwriting GUI changes.
    activation.seedFcitx = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/fcitx5"}
      for entry in config profile; do
        target=${lib.escapeShellArg "${config.xdg.configHome}/fcitx5"}/$entry
        if [ ! -e "$target" ]; then
          case "$entry" in
            config) run install -m 0644 ${../config/fcitx5/config} "$target" ;;
            profile) run install -m 0644 ${../config/fcitx5/profile} "$target" ;;
          esac
        fi
      done
    '';
  };
  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
  programs.bash = {
    enable = true;
    shellAliases = { ls = "ls --color=auto"; grep = "grep --color=auto"; };
    initExtra = ''PS1='[\u@\h \W]\$ ' '';
    profileExtra = ''
      if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';
  };
  programs.zoxide = { enable = true; enableBashIntegration = true; };
  fonts.fontconfig.enable = true;
  xdg.enable = true;
  xdg.configFile = builtins.listToAttrs (map (name: {
    inherit name;
    value = { source = ../config + "/${name}"; recursive = true; };
  }) [ "kitty" "mako" "nvim" "pandoc" "xremap" "yazi" "zathura" "waybar" ])
  // {
    "environment.d/60-dotfiles.conf".text = ''
      PATH=${config.home.profileDirectory}/bin:${homeDirectory}/.local/bin:/nix/var/nix/profiles/default/bin:''${PATH}
      XDG_DATA_DIRS=${config.home.profileDirectory}/share:/usr/local/share:/usr/share
      XMODIFIERS=@im=fcitx
      QT_IM_MODULE=fcitx
    '';
  };
  # The host session must manage graphical-session.target (Fedora does).
  systemd.user.services.xremap = lib.mkIf desktop {
    Unit = {
      Description = "xremap: Henkan to Super";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${pkgs.xremap}/bin/xremap --watch ${config.xdg.configHome}/xremap/config.yml";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
