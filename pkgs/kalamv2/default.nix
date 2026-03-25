{
  lib,
  pkgs,
  inputs,
  outputs,
  avante-nvim,
  ...
}:
let
  # nixvimLib = inputs.nixvim.lib.${pkgs.stdenv.hostPlatform.system};
  nixvim' = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  nixvimModule =
    let
      upkgs = import inputs.nixpkgs-unstable {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };

      mpkgs = import inputs.nixpkgs-master {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
    in
    {
      module = import ./config; # import the module directly
      # You can use `extraSpecialArgs` to pass additional arguments to your module files
      extraSpecialArgs =
        {
          inherit
            inputs
            outputs
            mpkgs
            upkgs
            avante-nvim
            ;
        }
        // import ./lib {
          inherit pkgs lib;
        };
    };
in
nixvim'.makeNixvimWithModule nixvimModule
