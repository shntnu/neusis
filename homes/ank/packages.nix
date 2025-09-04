{ pkgs, outputs, ... }:
with pkgs;
[
  duckdb
  jq
  mpv
  nix-output-monitor
  nix-fast-build
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
  glances
  gping
  procs
  bandwhich
  outputs.packages.${pkgs.system}.claude-code
]
++ pkgs.lib.optionals pkgs.stdenv.isLinux [
  extra-container
  nixos-shell
  quickemu
  nixos-generators
]
