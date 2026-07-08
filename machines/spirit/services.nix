{
  outputs,
  inputs,
  ...
}:
{
  imports = [
    outputs.nixosModules.monitoring
    outputs.nixosModules.sunshine
    inputs.nixos-generators.nixosModules.all-formats
  ];

  # Enable monitoring; alloy pushes to Grafana Cloud via oppy's alloy_key
  # secret, which isn't available on spirit. Disable alloy here so spirit
  # runs local Prometheus + Grafana only. Follow-up: mint a spirit-specific
  # alloy_key.age (or reuse oppy's under a shared recipients list).
  neusis.services.monitoring.enable = true;
  neusis.services.monitoring.alloy.enable = false;

  # Enable ZFS auto-snapshots (retention policy defined in modules/nixos/zfs.nix)
  neusis.zfs.autoSnapshot.enable = true;

  # Add udev rules and user for IPMI device
  users.groups.ipmiusers = {
    name = "ipmiusers";
  };

  services.udev.extraRules = ''
    KERNEL=="ipmi*", MODE="0660", GROUP="ipmiusers"
  '';

  # NFSv4 id mapping domain — must match Oppy's /etc/idmapd.conf for the
  # InfiniBand mount of Oppy's /work/{datasets,tools} exports on spirit.
  # Kept configured here so spirit can consume Oppy's shares consistently
  # once the client mounts are wired up (follow-up PR).
  services.nfs.idmapd.settings.General.Domain = "broadinstitute.org";

  boot.extraModprobeConfig = ''
    options nfsd nfs4_disable_idmapping=0
  '';

  services.emacs.enable = true;
}
