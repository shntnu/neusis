{
  lib,
  pkgs,
  inputs,
  outputs,
  avante-nvim,
  ...
}:
let
  nixvim = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  nixvimModule = {
    # Keep the caller's overlays and unfree policy instead of Nixvim's default
    # package set (jupytext.nvim is classified as unfree in 26.05).
    inherit pkgs;
    module = import ./config; # import the module directly
    # You can use `extraSpecialArgs` to pass additional arguments to your module files
    extraSpecialArgs = {
      inherit
        inputs
        outputs
        avante-nvim
        ;
    }
    // import ./lib {
      inherit pkgs lib;
    };
  };
in
nixvim.makeNixvimWithModule nixvimModule
