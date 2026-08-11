{
  lib,
  outputs,
  ...
}:
{
  # Defaults only: personal modules, including modules from external flakes,
  # remain authoritative for the user's Home Manager configuration.
  nixpkgs = {
    overlays = lib.mkDefault (builtins.attrValues outputs.overlays);
    config.allowUnfree = lib.mkDefault true;
  };

  home.stateVersion = lib.mkDefault "25.11";
  programs.home-manager.enable = lib.mkDefault true;
}
