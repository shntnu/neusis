{
  inputs,
  pkgs,
  ...
}:
let
  unstable = import inputs.nixpkgs-unstable { stdenv.hostPlatform.system = pkgs.stdenv.hostPlatform.system; };
in
{
  home.packages = [ pkgs.input-leap ];
}
