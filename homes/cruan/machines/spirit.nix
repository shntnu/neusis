# Default spirit home-manager entry point: reuse the user's oppy config.
# Diverge from oppy only if you actually need spirit-specific behavior.
{ ... }:
{
  imports = [ ./oppy.nix ];
}
