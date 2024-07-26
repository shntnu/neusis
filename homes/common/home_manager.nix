{outputs, ...}: {
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
  };

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
