{ inputs, ... }:
{
  # Sourced from afermg/nixos-config through the `amunoz-nixos-config` input.
  # That module is the single source of truth — the same profile is applied on
  # moby — so this file intentionally does not import any of neusis's common
  # Home Manager modules.
  imports = [
    inputs.amunoz-nixos-config.homeModules.amunoz
  ];
}
