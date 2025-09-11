{
  lib,
  config,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    outputs.nixosModules.monitoring
    outputs.nixosModules.sunshine
    inputs.nixos-generators.nixosModules.all-formats
  ];

  # FHS
  programs.nix-ld.enable = true;

  # Required for nvidia dc drivers
  services.xserver.enable = false;

  # Enable monitoring
  neusis.services.monitoring.enable = true;

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

  # Default system wide packages
  environment.systemPackages = with pkgs; [
    vim
    dive
    podman-tui
    ipmitool
  ];
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # Add udev rules and user for IPMI device
  users.groups.ipmiusers = {
    name = "ipmiusers";
  };
  services.udev.extraRules = ''
    KERNEL=="ipmi*", MODE="0660", GROUP="ipmiusers"
  '';

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
