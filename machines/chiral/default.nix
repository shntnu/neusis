# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # include NixOS-WSL modules
    inputs.nixos-wsl.nixosModules.default
    # If you want to use modules from other flakes (such as nixos-hardware):
    inputs.home-manager.nixosModule
    # inputs.nix-ld.nixosModules.nix-ld
    inputs.agenix.nixosModules.default
    {
      age.identityPaths = ["/home/ank/.ssh/id_ed25519"];
    }

    # You can also split up your configuration and import pieces of it here:
    ../common/substituters.nix
    ../common/input_device.nix
    ../common/ssh.nix
    ../common/us_eng.nix
  ];

  # WSL Config
  wsl.enable = true;
  wsl.defaultUser = "nixos";
  wsl.useWindowsDriver = true;

  # FHS
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs; # only for NixOS 24.05
};

  # NVidia and cuda support

  hardware = {
    # Enable OpenGL
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
      ];
    };

    # Enable nvidia container
    nvidia-container-toolkit.enable = true;
  };

  # Nvidia and Cuda support
  services.xserver.videoDrivers = ["nvidia"];
  nixpkgs.config.cudaSupport = true;

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
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };

  # Default system wide packages
  environment.systemPackages = with pkgs; [
    vim
    dive
    podman-tui
    docker-compose
    inputs.agenix.packages.x86_64-linux.default
  ];
  environment.shells = [pkgs.zsh];
  programs.zsh.enable = true;

  # Netowrking
  networking.hostName = "chiral";
  # networking.bridges.br0.interfaces = [ "enp2s0" "wlp131s0" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ank = {
    shell = pkgs.zsh;
    isNormalUser = true;
    # passwordFile = config.age.secrets.karkinos_pass.path;
    description = "Ankur Kumar";
    extraGroups = ["networkmanager" "wheel" "libvirtd" "qemu-libvirtd" "input"];
    openssh.authorizedKeys.keyFiles = [
      ../../homes/ank/id_rsa.pub
      ../../homes/ank/id_ed25519.pub
    ];
  };

  # Enable home-manager for users
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {inherit inputs outputs;};
  home-manager.users.ank = {
    imports = [
      inputs.agenix.homeManagerModules.default
      ../../homes/ank/machines/chiral.nix
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
