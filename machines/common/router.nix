{ ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;

    # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
    # By default, not automatically configure any IPv6 addresses.
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    # "net.ipv6.conf.${name}.accept_ra" = 2;
    # "net.ipv6.conf.${name}.autoconf" = 1;
  };
  networking.nftables.enable = true;
  networking.nftables.ruleset = ''
    table ip router {
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          oifname "enp2s0" counter masquerade
        }
    }
  '';
   

}
