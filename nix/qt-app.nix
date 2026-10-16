{ pkgs }:
# Keep Nix Qt plugins local to Nix apps. Fedora Qt must use Fedora plugins.
package:
pkgs.symlinkJoin {
  name = "${package.pname or package.name}-with-fcitx";
  paths = [ package ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    for binary in "$out"/bin/*; do
      [ -f "$binary" ] && [ -x "$binary" ] || continue
      wrapProgram "$binary" --prefix QT_PLUGIN_PATH : \
        "${pkgs.qt6Packages.fcitx5-qt}/${pkgs.qt6.qtbase.qtPluginPrefix}"
    done
    if [ -d "$out/share/applications" ]; then
      for desktopFile in "$out"/share/applications/*.desktop; do
        [ -f "$desktopFile" ] || continue
        original=$(readlink -f "$desktopFile")
        cp --remove-destination "$original" "$desktopFile"
        sed -i "s|${package}/bin/|$out/bin/|g" "$desktopFile"
      done
    fi
  '';
  meta = package.meta;
}
