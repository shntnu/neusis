{
  lib,
  nixpkgs,
  overlays ? { },
  ...
}:
let
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
  pkgsFor = lib.genAttrs systems (
    system:
    import nixpkgs {
      inherit system;
      overlays = builtins.attrValues overlays;
      config.allowUnfree = true;
    }
  );
in
{
  oppy = pkgsFor.x86_64-linux;
  spirit = pkgsFor.x86_64-linux;
  karkinos = pkgsFor.x86_64-linux;
  chiral = pkgsFor.x86_64-linux;
  darwin001 = pkgsFor.aarch64-darwin;
}
