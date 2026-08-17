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
    ./ollama.nix

    # Deployment configs
    inputs.disko.nixosModules.disko
    ./deployment/disko.nix
    ./deployment/vm.nix

    # CSLab infrastructure and monitoring
    outputs.nixosModules.cslab-infrastructure
    outputs.nixosModules.cslab-monitoring

    # Common config
    ../common/system.nix
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
    outputs.nixosModules.zfs
    ../common/sudo.nix
    ../common/security.nix
  ];

  neusis.tailscale = {
    enable = true;
    isPersistent = true;
    hostName = "spirit";
    forceHostName = true;
    # Spirit-specific auth key — rotating this file doesn't touch oppy's config.
    # authkey_file wins over persistent_authkey_file per modules/nixos/tailscale.nix.
    authkey_file = ../../secrets/spirit/tsauthkey.age;
    persistent_authkey_file = ../../secrets/common/persistent_cslab_mesh.age;
    clientIdFile = ../../secrets/common/tsclient.age;
    clientSecretFile = ../../secrets/common/tssecret.age;
    disableKeyExpiry = true;
    tailnetOrg = "shntnu.github";
  };

  neusis.cslab.infrastructure = {
    enable = true;
    userConfigPath = ../../users/cslab_spirit.nix;
    testScriptPath = ./cslab/scripts/test-cslab-infrastructure.sh;
    # dataRoot defaults to "/work" — correct for Spirit
    # imagingGid defaults to 1000 — correct for Spirit
  };

  # Monitoring is deferred to a follow-up PR after Spirit's fresh ssh_host_ed25519_key
  # is generated and added to secrets/secrets.nix, so slack_webhook.age can be
  # re-encrypted to include Spirit as a recipient.
  #
  # neusis.cslab.monitoring = {
  #   enable = true;
  #   userConfigPath = ../../users/cslab_spirit.nix;
  #   machineName = "Spirit";
  #   slackWebhookSecretFile = ../../secrets/spirit/slack_webhook.age;
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
