{ ... }:
{
  boot.kernelParams = [ "nohibernate" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = true;
  boot.zfs.forceImportAll = true;
  services = {
    zfs.autoScrub.enable = true;
    zfs.trim.enable = true;
    nfs.server.enable = true;
  };
}
