{ inputs, ... }:
{
  # Sourced from afermg/nixos-config through the `amunoz-nixos-config` input.
  # The exported Oppy profile includes the shared personal configuration plus
  # host-specific secrets and services such as Pi-msg, so this file intentionally
  # does not duplicate that wiring or import Neusis's common Home Manager modules.
  imports = [
    inputs.amunoz-nixos-config.homeModules."amunoz-oppy"
  ];
}
