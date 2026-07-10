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
  services.nfs.idmapd.settings.General.Domain = "broadinstitute.org";

  # NFS client mount of Oppy's /work/datasets over the InfiniBand link
  # (oppy = 192.0.2.1, spirit = 192.0.2.2 — see network.nix "50-infiniband").
  # Reinstates the Ubuntu-era share (maintenance log 2026-02-17), declarative
  # this time. Lazy via systemd automount: mounted on first access, unmounted
  # after 10 min idle, so boot never blocks and Oppy downtime can't wedge an
  # unused mount. Mount stays `hard` (default) — `soft` risks silent data
  # corruption on writable NFS. Path is /work/oppy/* (not the old /mnt/oppy/*)
  # so remote data sits next to local /work/datasets; /work/oppy/tools can
  # join later.
  fileSystems."/work/oppy/datasets" = {
    device = "192.0.2.1:/work/datasets";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "nofail"
      "_netdev"
      "x-systemd.idle-timeout=10min"
      "x-systemd.mount-timeout=30s"
      "nfsvers=4.2"
    ];
  };

  boot.extraModprobeConfig = ''
    options nfsd nfs4_disable_idmapping=0
  '';

  services.emacs.enable = true;
}
