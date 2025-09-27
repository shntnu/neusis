{ outputs, ... }:
{
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
  };

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
