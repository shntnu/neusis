{ ... }:
{
  # Bootloader
  boot.shell_on_fail = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "/dev/nvme4n1";
  };
}
