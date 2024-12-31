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
    inputs.agenix.nixosModules.default
    {
      age.identityPaths = ["/home/ank/.ssh/id_ed25519"];
    }

    # You can also split up your configuration and import pieces of it here:
    ../common/substituters.nix
    ../common/input_device.nix
    ../common/ssh.nix
    ../common/us_eng.nix
    ../common/nix.nix
  ];

  # Hardware config
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # WSL Config
  wsl = {
    enable = true;
    defaultUser = "ank";
    useWindowsDriver = true;
    docker-desktop = {enable = true;};
    nativeSystemd = true;
  };

  # FHS
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };

  # NVidia and cuda support

  hardware = {
    # nvidia prop drivers
    nvidia.open = false;
    graphics.enable = true;
    # Enable OpenGL
    opengl = {
      enable = true;
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
    inputs.agenix.packages.x86_64-linux.default
    home-manager
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
      # include nixvim module
      inputs.stylix.homeManagerModules.stylix
      ../../homes/ank/machines/chiral.nix
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
