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

  # Enable monitoring
  neusis.services.monitoring.enable = true;

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
