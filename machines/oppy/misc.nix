{
  lib,
  config,
  pkgs,
  inputs,
  outputs,
  ...
}:
{

  # FHS
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
      sunshine = {
        cudaSupport = true;
      };
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
    (lib.filterAttrs (_: lib.isType "flake")) inputs
  );

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  # Default system wide packages
  environment.systemPackages = with pkgs; [
    vim
    dive
    podman-tui
  ];
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # Networking
  networking.hostName = "oppy";

  networking.hostId = "2e39dfae"; # The primary use case is to ensure when using ZFS that a pool isn’t imported accidentally on a wrong machine.
  # networking.bridges.br0.interfaces = [ "enp2s0" "wlp131s0" ];
}
