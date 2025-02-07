{ ... }:
{
  # Bootloader
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = "/dev/nvme4n1";
  };
}
