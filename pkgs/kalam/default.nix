{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  nixvimLib = inputs.nixvim.lib.${pkgs.system};
  nixvim' = inputs.nixvim.legacyPackages.${pkgs.system};
  nixvimModule = {
    inherit pkgs;
    module = import ./config; # import the module directly
    # You can use `extraSpecialArgs` to pass additional arguments to your module files
    extraSpecialArgs = {
      inherit inputs;
    } // import ./lib { inherit lib pkgs; };
  };
in
nixvim'.makeNixvimWithModule nixvimModule
