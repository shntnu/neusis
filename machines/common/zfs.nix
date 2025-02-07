{ ... }:
{
  boot.kernelParams = [ "nohibernate" ];
  services = {
    zfs.autoScrub.enable = true;
    zfs.trim.enable = true;
    nfs.server.enable = true;
  };
}
