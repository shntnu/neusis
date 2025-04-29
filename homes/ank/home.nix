{ pkgs, ... }:
{
  home = {
    username = "ank";
    homeDirectory = "/home/ank";

    packages = import ./packages.nix { inherit pkgs; };
  };
}
