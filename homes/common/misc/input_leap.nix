{
  inputs,
  pkgs,
  ...
}:
let
  unstable = import inputs.nixpkgs-unstable { system = pkgs.system; };
in
{
  home.packages = [ pkgs.input-leap ];
}
