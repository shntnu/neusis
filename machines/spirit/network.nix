# MAC Addresses (verified 2026-07-07 via live recon on Ubuntu spirit)

# Intel X710 10G SFP+ (LACP bonded)
# enp206s0f0 = 40:a6:b7:cc:d8:e8
# enp206s0f1 = 40:a6:b7:cc:d8:e9

{ ... }:
let
  ether_slave_00_mac = "40:a6:b7:cc:d8:e8";
  ether_slave_01_mac = "40:a6:b7:cc:d8:e9";
in
{

  networking.hostName = "spirit";
  networking.hostId = "1ecc64dc"; # First 8 hex of /etc/machine-id — unique per host to guard ZFS pool imports.

  # Enable infiniband — Mellanox mlx5_0 → ibp69s0
  hardware.infiniband.enable = true;
  hardware.infiniband.guids = [
    # spirit mellanox port guid (from /sys/class/infiniband/mlx5_0/ports/1/gids/0)
    "0xa088c20300885ac4"
  ];

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
          MIIMonitorSec = "100ms";
          TransmitHashPolicy = "layer3+4";
        };
      };
    };
    networks = {
      "30-enp206s0f0" = {
        matchConfig.MACAddress = ether_slave_00_mac;
        networkConfig.Bond = "bond001";
        linkConfig.RequiredForOnline = "yes";
      };

      "30-enp206s0f1" = {
        matchConfig.MACAddress = ether_slave_01_mac;
        networkConfig.Bond = "bond001";
        linkConfig.RequiredForOnline = "yes";
      };

      "40-bond001" = {
        matchConfig.Name = "bond001";
        linkConfig.RequiredForOnline = "no";

        # Static assignment (mirrors oppy's pattern; DHCP-registered hostname
        # from Ubuntu was 10.192.6.24, preserved here).
        networkConfig = {
          Address = "10.192.6.24/24";
          Gateway = "10.192.6.1";
          DNS = [ "10.2.1.1" ];
          DHCP = "no";
        };
      };

      # InfiniBand point-to-point with oppy (oppy = 192.0.2.1, spirit = 192.0.2.2)
      "50-infiniband" = {
        matchConfig.Name = "ibp69s0";
        networkConfig = {
          Address = "192.0.2.2/24";
          DHCP = "no";
        };
        linkConfig.RequiredForOnline = "no";
      };
    };

  };
}
