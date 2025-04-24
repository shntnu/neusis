{
  lib,
  pkgs,
  inputs,
  outputs,
  avante-nvim,
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

      mpkgs = import inputs.nixpkgs-master {
        inherit (pkgs) system;
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
