{ pkgs, outputs, ... }:
{
  home.packages = [
    outputs.packages.${pkgs.system}.kalamv2
  ];
}
