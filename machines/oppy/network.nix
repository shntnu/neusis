{ ... }:
{
  systemd.network.wait-online.enable = false;
  systemd.network = {
    enable = true;
    netdevs = {
      "10-bond001" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond001";
        };
        bondConfig = {
          Mode = "802.3ad";
          MIIMonitorSec = "0.100s";
          TransmitHashPolicy = "layer3+4";
        };
      };
    };
    networks = {
      "30-enp206s0f0" = {
        matchConfig.Name = "enp206s0f0";
        networkConfig.Bond = "bond001";
      };

      "30-enp206s0f1" = {
        matchConfig.Name = "enp206s0f1";
        networkConfig.Bond = "bond001";
      };

      "40-bond001" = {
        matchConfig.Name = "bond001";
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          Address = "10.192.6.25/24";
          Gateway = "10.192.6.255";
          DNS = [ "10.2.1.1" ];
          DHCP = "no";
        };

      };
    };

  };
}
