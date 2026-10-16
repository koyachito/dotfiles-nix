{ lib, desktop, ... }:
{
  # The portable home module does not depend on Fedora's Sway helper.
  xdg.configFile = lib.mkIf desktop {
    "sway/config".text = builtins.replaceStrings
      [ "include /etc/sway/config.d/*"
        "output * bg /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png fill" ]
      [ ''include '$(/usr/libexec/sway/layered-include "/usr/share/sway/config.d/*.conf" "/etc/sway/config.d/*.conf" "''${XDG_CONFIG_HOME:-$HOME/.config}/sway/config.d/*.conf")' ''
        "output * bg #1e1e2e solid_color" ]
      (builtins.readFile ../config/sway/config);
    # Keep Fedora session/portal/polkit fragments; avoid duplicate bar and bindings.
    "sway/config.d/90-bar.conf".text = "# Waybar is started by the main config.\n";
    "sway/config.d/90-swayidle.conf".text = "# swayidle is started by the main config.\n";
    "sway/config.d/60-bindings-brightness.conf".text = "# Bindings in main config.\n";
    "sway/config.d/60-bindings-volume.conf".text = "# Bindings in main config.\n";
    "sway/config.d/60-bindings-screenshot.conf".text = "# Bindings in main config.\n";
    "autostart/org.fcitx.Fcitx5.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Fcitx5 (started by Sway)
      Hidden=true
    '';
  };
}
