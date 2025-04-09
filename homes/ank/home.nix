{ pkgs, ... }:
{
  home = {
    username = "ank";
    homeDirectory = "/home/ank";

    packages = with pkgs; [
      duckdb
      jq
      mpv
      nix-output-monitor
      nh
      nixos-shell
      television
      comma
      manix
      nix-index
      nix-diff
      nix-du
      nix-melt
      nix-tree
      nix-init
      nvd
      nurl
      statix
      extra-container
    ];
  };
}
