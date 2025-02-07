{ ... }:
{
  # Bootloader
  boot.shell_on_fail = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        devices = [ "/dev/nvme4n1" ];
        path = "/boot";
      }
    ];
  };
}
