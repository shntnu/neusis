{
  pkgs ? import <nixpkgs> { },
  inputs,
  outputs,
}:
{
  kalam = pkgs.callPackage ./kalam { inherit inputs outputs; };
  kalamv2 = pkgs.callPackage ./kalamv2 { inherit inputs outputs; };
  kalampy = pkgs.callPackage ./kalampy { inherit inputs outputs; };
}
