{
  description = "Portable Home Manager environment with Fedora Sway integration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, home-manager, ... }:
    let
      # Edit these two values for the Fedora login account before applying.
      username = "koyachito";
      homeDirectory = "/home/${username}";
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      mkHome = { desktop ? false, host ? "generic" }: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit username homeDirectory desktop; };
        modules = [ ./nix/home.nix ]
          ++ (if host == "fedora" then [ ./nix/fedora.nix ] else [ ]);
      };
    in {
      homeConfigurations.linux-base = mkHome { };
      homeConfigurations.fedora-base = mkHome { host = "fedora"; };
      homeConfigurations.fedora = mkHome { host = "fedora"; desktop = true; };
    };
}
