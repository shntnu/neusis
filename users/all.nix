{ self, pkgs, ... }:
let
  userConfigList = [
    (import ./cslab.nix { inherit pkgs; })
    (import ./cslab_karkinos.nix { inherit pkgs; })
    (import ./ank.nix { inherit pkgs; })
  ];
in
self.lib.neusisOS.mergeUserConfigs userConfigList
