{ pkgs, outputs, ... }:
with pkgs;
[
  duckdb
  jq
  pkgs.unstable.mpv
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
  outputs.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
  bitwarden-desktop
  pnpm
  mosh
]
++ pkgs.lib.optionals pkgs.stdenv.isLinux [
  extra-container
  nixos-shell
  quickemu
  nixos-generators
]
++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
  # goes out of date very quickly
  # pkgs.master.signal-desktop-bin
  # pkgs.master.whatsapp-for-mac
  spotify
  obsidian
  # broken right now. uncomment later
  #pkgs.unstable.blender
]
