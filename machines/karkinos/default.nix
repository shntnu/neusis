# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.home-manager.nixosModule
    outputs.nixosModules.sunshine
    # inputs.nixos-nvidia-vgpu.nixosModules.nvidia-vgpu
    # {
    #   # boot.kernelPackages = pkgs.linuxPackages_6_1;
    #   hardware.nvidia.vgpu = {
    #     pinKernel = true;
    #     copyVGPUProfiles = {
    #       "26B1:0000"="26B1:170B";
    #     };
    #     enable = true;
    #     fastapi-dls = {
    #       enable = true;
    #     };
    #   };
    # }

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Disko configuration
    inputs.disko.nixosModules.disko
    ./disko.nix
    # Path to make boot work with zstore pool
    ./filesystem.nix
    ../common/zfs.nix

    # You can also split up your configuration and import pieces of it here:
    ../common/networking.nix
    ../common/printing.nix
    ../common/gpu/nvidia.nix
    ../common/substituters.nix
    ../common/pipewire.nix
    ../common/virtualization.nix
    ../common/input_device.nix
    ../common/ssh.nix
    ../common/us_eng.nix
    ../common/router.nix
    ../common/nosleep.nix
    ../common/nix.nix
  ];

  # FHS
  programs.nix-ld.enable = true;
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.autoSuspend = false;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable sunshine
  modules.services.sunshine.enable = true;

  # enable ollama
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama;
    acceleration = "cuda";
    models = "/datastore/ollama";
    host = "0.0.0.0";
    port = 11434;
  };

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
    unstable.ollama
    gnomeExtensions.forge
    gnomeExtensions.blur-my-shell
    gnomeExtensions.burn-my-windows
    gnomeExtensions.appindicator
  ];
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  # Networking
  networking.hostName = "GPFDA-11A";

  networking.hostId = "df6b910c"; # The primary use case is to ensure when using ZFS that a pool isn’t imported accidentally on a wrong machine.
  # networking.bridges.br0.interfaces = [ "enp2s0" "wlp131s0" ];
  services.tailscale.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ank = {
    shell = pkgs.zsh;
    isNormalUser = true;
    initialPassword = "changeme";
    # passwordFile = config.age.secrets.karkinos_pass.path;
    description = "Ankur Kumar";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "qemu-libvirtd"
      "input"
      "podman"
      "docker"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../../homes/ank/id_rsa.pub
      ../../homes/ank/id_ed25519.pub
      ../../homes/ank/id2_ed25519.pub
    ];
  };

  users.users.niv = {
    shell = pkgs.zsh;
    isNormalUser = true;
    # passwordFile = config.age.secrets.karkinos_pass.path;
    description = "Niveditha";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "qemu-libvirtd"
      "input"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../../homes/niv/id_ed25519.pub
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jarevalo = {
    shell = pkgs.zsh;
    isNormalUser = true;
    # passwordFile = config.age.secrets.karkinos_pass.path;
    description = "John Arevalo";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "qemu-libvirtd"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../../homes/jarevalo/id_ed25519.pub
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ashah = {
    shell = pkgs.zsh;
    isNormalUser = true;
    # passwordFile = config.age.secrets.karkinos_pass.path;
    description = "Adit Shah";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "qemu-libvirtd"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../../homes/ashah/id_rsa.pub
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.suganya = {
    shell = pkgs.zsh;
    isNormalUser = true;
    # passwordFile = config.age.secrets.karkinos_pass.path;
    description = "Suganya";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "qemu-libvirtd"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../../homes/suganya/id_ed25519.pub
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.leliu = {
    shell = pkgs.zsh;
    isNormalUser = true;
    # passwordFile = config.age.secrets.karkinos_pass.path;
    description = "Le Lui";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "qemu-libvirtd"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../../homes/leliu/id_ed25519.pub
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.skhosrav = {
    shell = pkgs.zsh;
    isNormalUser = true;
    # passwordFile = config.age.secrets.karkinos_pass.path;
    description = "Sara Khosravi";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "qemu-libvirtd"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../../homes/skhosrav/id_ed25519.pub
    ];
  };
  home-manager = {

    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs outputs; };

    # Enable home-manager for users
    users = {
      ank = {
        imports = [
          inputs.agenix.homeManagerModules.default
          ../../homes/ank/machines/karkinos.nix
        ];
      };
      niv = {
        imports = [
          inputs.agenix.homeManagerModules.default
          ../../homes/niv/machines/karkinos.nix
        ];
      };
      jarevalo = {
        imports = [
          inputs.agenix.homeManagerModules.default
          ../../homes/jarevalo/machines/karkinos.nix
        ];
      };
      suganya = {
        imports = [
          inputs.agenix.homeManagerModules.default
          ../../homes/suganya/machines/karkinos.nix
        ];
      };
      leliu = {
        imports = [
          inputs.agenix.homeManagerModules.default
          ../../homes/leliu/machines/karkinos.nix
        ];
      };
      skhosrav = {
        imports = [
          inputs.agenix.homeManagerModules.default
          ../../homes/skhosrav/machines/karkinos.nix
        ];
      };
      ashah = {
        imports = [
          inputs.agenix.homeManagerModules.default
          ../../homes/ashah/machines/karkinos.nix
        ];
      };
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
