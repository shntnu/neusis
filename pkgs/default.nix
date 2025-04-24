{
  pkgs ? import <nixpkgs> { },
  inputs,
  outputs,
}:
rec {
  avante-nvim = pkgs.callPackage ./avante-nvim { };
  kalam = pkgs.callPackage ./kalam { inherit inputs outputs; };
  kalamv2 = pkgs.callPackage ./kalamv2 { inherit inputs outputs avante-nvim; };
  kalampy = pkgs.callPackage ./kalampy { inherit inputs outputs; };
}
