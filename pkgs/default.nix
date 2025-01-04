{
  pkgs ? import <nixpkgs> { },
  inputs,
  outputs,
}:
{
  kalam = pkgs.callPackage ./kalam { inherit inputs outputs; };
}
