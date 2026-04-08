{ outputs, ... }:
{
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
  };

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
