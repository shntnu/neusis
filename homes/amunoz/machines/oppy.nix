{ inputs, ... }:
{
  # Sourced from amunoz's own flake at
  # /home/amunoz/.local/share/src/nixos-config (added as the
  # `amunoz-nixos-config` input in neusis's flake.nix). That module is the
  # single source of truth — same profile is applied on moby — so this file
  # intentionally does not import any of neusis's common home-manager modules.
  imports = [
    inputs.amunoz-nixos-config.homeModules.amunoz
  ];
}
