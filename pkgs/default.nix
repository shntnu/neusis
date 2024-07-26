{pkgs ? import <nixpkgs> {}}: {
  sst = pkgs.callPackage ./sst {};
  typedb = pkgs.callPackage ./typedb {};
  nvidia_vgpu = pkgs.callPackage ./nvidia_vgpu {};
}
