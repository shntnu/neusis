{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}:
{
  imports = [
    ../../common/home_manager.nix
    ../../common/dev
    ../../common/dev/kalam.nix
    ../../common/themes
    ../../common/browsers/brave.nix
    ../configs/tmux.nix
    ../configs/opencode.nix
    (import ../../common/dev/editors.nix {
      inherit pkgs config inputs;
      enableNvim = false;
      enableAstro = false;
    })
    (import ../../common/dev/git.nix {
      username = "Ankur Kumar";
      userEmail = "ank@leoank.me";
      id_ed25519_pub = builtins.readFile ../id_ed25519.pub;
    })
  ];

  # Configure nixpkgs
  nixpkgs = {
    # You can add overlays here
    overlays = builtins.attrValues outputs.overlays;
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  home.username = "ank";
  home.homeDirectory = "/Users/ank";
  home.packages = import ../packages.nix { inherit pkgs outputs; };

  # Add sketchybar config
  # xdg.configFile."sketchybar" = {
  #   source = ../configs/sketchybar;
  #   recursive = true;
  # };

  # Add hammerspoon config
  xdg.configFile."hammerspoon" = {
    source = ../configs/hammerspoon;
    recursive = true;
  };
}
