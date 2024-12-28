{outputs, ...}: {
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
  };

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
