{ ... }:
{
  # Bootloader
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        devices = [
          "/dev/nvme4n1"
          "/dev/nvme0n1"
        ];
        path = "/boot";
      }
    ];
  };
}
