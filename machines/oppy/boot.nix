{ ... }:
{
  # Bootloader
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "/dev/nvme4n1" ];
  };
}
