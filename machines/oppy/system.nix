{
  lib,
  config,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  # FHS compatibility
  programs.nix-ld.enable = true;

  # Required for nvidia dc drivers
  services.xserver.enable = false;

  # Have to add this to make theme related things work in GUI less env
  programs.dconf.enable = true;

  nixpkgs = {
    # You can add overlays here
    overlays = builtins.attrValues outputs.overlays;
    # Configure your nixpkgs instance
    config = {
      cudaSupport = true;
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # nixos generator settings
  formatConfigs.install-iso =
    { lib, ... }:
    {
      # We can enable it if we make some interface unmanaged
      # networking.networkmanager.unmanaged = [];
      networking.wireless.enable = false;
      neusis.tailscale.hostName = lib.mkForce "install-oppy";

    };
}
