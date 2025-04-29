{ pkgs, ... }:
with pkgs;
[
  duckdb
  jq
  mpv
  nix-output-monitor
  nh
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
  bat
  eza
]
++ pkgs.lib.optionals pkgs.stdenv.isLinux [
  extra-container
  nixos-shell
  quickemu
  nixos-generators
]
