{
  inputs,
  outputs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    outputs.nixosModules.tailscale
    outputs.nixosModules.monitoring

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # boot config
    ./boot.nix

    # Disko configuration
    inputs.disko.nixosModules.disko
    ./disko.nix

    # Path to make boot work with zstore pool
    #./filesystem.nix

    # networking config
    ./network.nix

    # karinos misc
    ./misc.nix

    # vm related
    ./vm.nix

    # common config
    ../common/system.nix
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

  neusis.tailscale = {
    enable = true;
    isPersistent = true;
    hostName = "karkinos";
    forceHostName = true;
    persistent_authkey_file = ../../secrets/common/persistent_cslab_mesh.age;
    clientIdFile = ../../secrets/common/tsclient.age;
    clientSecretFile = ../../secrets/common/tssecret.age;
    disableKeyExpiry = true;
    tailnetOrg = "shntnu.github";
  };

  neusis.services.monitoring = {
    enable = true;
    alloy.enable = false;
  };
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
