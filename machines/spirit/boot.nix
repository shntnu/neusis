{ pkgs, ... }:
{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Zfs pool import issue: https://github.com/nix-community/disko/issues/359
  system.activationScripts."importzfs" = ''
    ${pkgs.zfs}/bin/zpool import -fa
  '';
}
