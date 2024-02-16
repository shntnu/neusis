{ inputs, ... }:
{
  imports = [
     inputs.agenix.homeManagerModules.default
    ./tsauthkey.nix
  ];
}
