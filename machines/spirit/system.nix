{ ... }:
{
  # Required for nvidia dc drivers
  services.xserver.enable = false;

  nixpkgs.config.cudaSupport = true;

  # nixos generator settings
  formatConfigs.install-iso =
    { lib, ... }:
    {
      networking.wireless.enable = false;
      neusis.tailscale.hostName = lib.mkForce "install-spirit";
    };
}
