{
  pkgs ? import <nixpkgs> { },
  inputs,
  outputs,
}:
rec {
  avante-nvim = pkgs.callPackage ./avante-nvim { };
  claude-code = pkgs.callPackage ./claude-code { };
  claude-code-router = pkgs.callPackage ./claude-code-router { };
  #kalam = pkgs.callPackage ./kalam { inherit inputs outputs; };
  kalamv2 = pkgs.callPackage ./kalamv2 { inherit inputs outputs avante-nvim; };
  #kalampy = pkgs.callPackage ./kalampy { inherit inputs outputs; };
  xrt = pkgs.callPackage ./xilinx/xrt.nix { };
  xrt-drivers = pkgs.callPackage ./xilinx/xrt-drivers.nix {
    inherit xrt;
    kernel = pkgs.linux;
  };
  xilinx-env = pkgs.callPackage ./xilinx/fhs-env.nix { };
  xilinx-firmware = pkgs.callPackage ./xilinx/firmware-u250.nix { };
  xntools-core = pkgs.callPackage ./xilinx/xntools-core.nix { };
  firmware-sn1000 = pkgs.callPackage ./xilinx/firmware-sn1000.nix { };
  xilinx-cable-drivers = pkgs.callPackage ./xilinx/cable-drivers { };
  intel-cable-drivers = pkgs.callPackage ./intel-fpgas/cable-drivers { };
  intel-opencl-drivers = pkgs.callPackage ./intel-fpgas/opencl-drivers { };
}
