{ ... }:
{
  networking.networkmanager.enable = true;
  networking.firewall = {};
  systemd.services.NetworkManager-wait-online.enable = false;
}
