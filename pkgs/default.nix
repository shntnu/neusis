{
  pkgs ? import <nixpkgs> { },
  inputs,
}:
{
  kalam = pkgs.callPackage ./kalam { inherit inputs; };
}
