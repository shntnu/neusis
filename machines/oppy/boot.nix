{ ... }:
{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # https://discourse.nixos.org/t/cannot-import-zfs-pool-at-boot/4805/18
  boot.zfs.devNodes = "/dev/disk/by-id";
}
