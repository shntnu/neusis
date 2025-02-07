{ ... }:
{
  # Bootloader
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "/dev/nvme4n1";
  };
}
