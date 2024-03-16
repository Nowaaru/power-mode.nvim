{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (pkgs) neovimUtils;
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [
        defaultOverlay
      ];
    };

    defaultOverlay = _: prev: {
      prev.vimPlugins.power-mode-nvim = neovim-plugin;
    };

    neovim-plugin = pkgs.stdenv.mkDerivation { 
      pname = "power-mode.nvim";
      version = "2024-03-07";
      src = ./src;

      buildPhase = ''
        mkdir $out;
      '';

      installPhase = ''
        echo huh
        ls $src
        echo testing 3
        cp -r $src/* $out
      '';

      meta = {};
    };
  in rec {
    packages.x86_64-linux.default = neovim-plugin;

    overlays.default = defaultOverlay;
    overlays.power-mode-nvim = overlays.default;
  };
}
