{ lib, config, ... }:
{
  options.neusis.zfs.autoSnapshot.enable =
    lib.mkEnableOption "ZFS auto-snapshots with CSLab retention policy";

  config = {
    boot.kernelParams = [ "nohibernate" ];
    boot.initrd.supportedFilesystems = [ "zfs" ];
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = true;
    boot.zfs.forceImportAll = true;
    services = {
      zfs.autoScrub.enable = true;
      zfs.trim.enable = true;
    };

    # CSLab retention policy: opt-in per machine.
    # Lean policy — keep only the most recent daily + monthly. Manual
    # snapshots (@manual-*, @jump-prod-*) are user-created and untouched
    # by the auto-snapshot service, so they persist independently.
    services.zfs.autoSnapshot = lib.mkIf config.neusis.zfs.autoSnapshot.enable {
      enable = true;
      frequent = 0;   # not used (timer disabled below)
      hourly = 0;     # not used (timer disabled below)
      daily = 1;      # keep only the most recent
      weekly = 0;     # not used (timer disabled below)
      monthly = 1;    # keep only the most recent
    };

    # NixOS's services.zfs.autoSnapshot enables ALL five timers regardless
    # of retention count. `count=0` only tells the script to keep 0 — it
    # still runs on schedule. Disable the three we don't want at the
    # systemd level so the timer list stays honest.
    systemd.timers = lib.mkIf config.neusis.zfs.autoSnapshot.enable {
      zfs-snapshot-frequent.enable = false;
      zfs-snapshot-hourly.enable = false;
      zfs-snapshot-weekly.enable = false;
    };
  };
}
