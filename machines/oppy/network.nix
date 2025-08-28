# MAC Addresses

# Intel X710 10G SFP+
# enp206s0f0 = 40:a6:b7:cc:d9:00
# enp206s0f1 = 40:a6:b7:cc:d9:01

# Mellanox 400G QSFP+
# ibp69s0 = 80:00:04:db:fe:80:00:00:00:00:00:00:a0:88:c2:03:00:88:a3:14
{ ... }:
let
  oppyLinks = {
    "05-salve0".extraConfig = ''
      [Match]
      MACAddress = 40:a6:b7:cc:d9:00
      Type = ether

      [Link]
      Name = intel_10g_slave0
    '';
    "05-salve1".extraConfig = ''
      [Match]
      MACAddress = 40:a6:b7:cc:d9:01
      Type = ether

      [Link]
      Name = intel_10g_slave1
    '';
    "05-infiniband".extraConfig = ''
      [Match]
      MACAddress = 80:00:04:db:fe:80:00:00:00:00:00:00:a0:88:c2:03:00:88:a3:14
      Type = infiniband

      [Link]
      Name = mellanox_400g
    '';
  };
in
{

  systemd.network.wait-online.enable = false;
  systemd.network = {
    # Enable networkd
    enable = true;
    links = oppyLinks;
    netdevs = {
      "10-bond001" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond001";
        };
        bondConfig = {
          Mode = "802.3ad";
          MIIMonitorSec = "100ms";
          TransmitHashPolicy = "layer3+4";
        };
      };
    };
    networks = {
      "30-enp206s0f0" = {
        matchConfig.Name = "intel_10g_slave0";
        networkConfig.Bond = "bond001";
        linkConfig.RequiredForOnline = "yes";
      };

      "30-enp206s0f1" = {
        matchConfig.Name = "intel_10g_slave1";
        networkConfig.Bond = "bond001";
        linkConfig.RequiredForOnline = "yes";
      };

      "40-bond001" = {
        matchConfig.Name = "bond001";
        linkConfig.RequiredForOnline = "no";
        networkConfig = {
          DHCP = "yes";
        };
        dhcpV4Config = {
          # Hostname registered with Broad IT
          Hostname = "sn4622121098";
        };

        # If DHCPv4 fails to work
        # networkConfig = {
        #   Address = "10.192.6.25/24";
        #   Gateway = "10.192.6.1";
        #   DNS = [ "10.2.1.1" ];
        #   DHCP = "no";
        # };
        # extraConfig = ''
        #   [Route]
        #   Gateway = 10.192.6.1
        #   GatewayOnLink = yes
        #   Destination =
        #   Source =
        #   Metric =
        # '';

        extraConfig = ''
          [DHCPv4]
          Hostname = sn4622121098

        '';
      };

      "50-infiniband" = {
        matchConfig.Name = "mellanox_400g";
        networkConfig = {
          Address = "192.0.2.1/24";
          DHCP = "no";
        };
        linkConfig.RequiredForOnline = "no";
      };
    };

  };
}
