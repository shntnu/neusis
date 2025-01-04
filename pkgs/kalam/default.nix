{
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  # nixvimLib = inputs.nixvim.lib.${pkgs.system};
  nixvim' = inputs.nixvim.legacyPackages.${pkgs.system};
  nixvimModule =
    let
      upkgs = import inputs.nixpkgs-unstable {
        inherit (pkgs) system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
    in
    {
      pkgs = upkgs;
      module = import ./config; # import the module directly
      # You can use `extraSpecialArgs` to pass additional arguments to your module files
      extraSpecialArgs =
        {
          inherit inputs outputs;
        }
        // import ./lib {
          inherit lib;
          pkgs = upkgs;
        };
    };
in
nixvim'.makeNixvimWithModule nixvimModule
