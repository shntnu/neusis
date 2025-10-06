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

    ./hardware-configuration.nix

    # System configuration
    ./boot.nix
    ./network.nix
    ./system.nix
    ./packages.nix
    ./services.nix

    # Deployment configs
    inputs.disko.nixosModules.disko
    ./deployment/disko.nix
    ./deployment/vm.nix

    # CSLab infrastructure and monitoring
    ./cslab/infrastructure.nix
    ./cslab/monitoring.nix

    # Common config
    ../common/networking.nix
    ../common/gpu/nvidia_dc.nix
    ../common/substituters.nix
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
    hostName = "oppy";
    forceHostName = true;
    persistent_authkey_file = ../../secrets/common/persistent_cslab_mesh.age;
    clientIdFile = ../../secrets/common/tsclient.age;
    clientSecretFile = ../../secrets/common/tssecret.age;
    disableKeyExpiry = true;
    tailnetOrg = "shntnu.github";
  };
  
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
