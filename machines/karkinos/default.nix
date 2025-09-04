{
  inputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.home-manager.nixosModules.home-manager

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # boot config
    ./boot.nix

    # Disko configuration
    inputs.disko.nixosModules.disko
    ./disko.nix

    # Path to make boot work with zstore pool
    ./filesystem.nix

    # networking config
    ./network.nix

    # karinos misc
    ./misc.nix

    # vm related
    ./vm.nix

    # common config
    #../common/grub_bootloader.nix
    ../common/networking.nix
    ../common/gpu/nvidia_dc.nix
    ../common/substituters.nix
    ../common/pipewire.nix
    ../common/virtualization.nix
    ../common/input_device.nix
    ../common/ssh.nix
    ../common/us_eng.nix
    ../common/nosleep.nix
    ../common/nix.nix
    ../common/printing.nix
    ../common/zfs.nix
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
