{
  description = "Neusis: Crafting systems";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    # flake-parts
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Auto upgrades
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # submodule
    astroank = {
      url = "github:leoank/astroank";
      flake = false;
    };

    #------------------------------------------------------------
    # nixvim
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix/release-25.05";

    #------------------------------------------------------------

    # wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    # darwin inputs
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    vancluever-tap = {
      url = "github:vancluever/homebrew-input-leap";
      flake = false;
    };
    fuse-t-cask = {
      url = "github:macos-fuse-t/homebrew-cask";
      flake = false;
    };
    nikitabobko-cask = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

    # disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # VS Code
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix.url = "github:ryantm/agenix";

    hardware.url = "github:nixos/nixos-hardware";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    # Define all the reusable modules for external use
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        withSystem,
        moduleWithSystem,
        flake-parts-lib,
        self,
        lib,
        ...
      }:
      let
        inherit (flake-parts-lib) importApply;

        # Helper
        mkImportApply =
          moduleFileAttrs:
          builtins.mapAttrs (
            name: value:
            importApply value {
              localFlake = self;
              inherit withSystem moduleWithSystem flake-parts-lib;
              #inherit (inputs) nixpkgs;
            }
          ) moduleFileAttrs;

        # Flake modules for external and internal use
        publicFlakeModules =
          rec {
            default = ./flakeModules/lib.nix;
            neusis = default;

          }
          // mkImportApply rec {
          };
      in
      {
        debug = true;
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];

        imports = [
          ./flakeModules/neusisOSConfigs
          ./flakeModules/checks
          ./flakeModules/packages.nix
          ./flakeModules/lib.nix
        ];
        flake = rec {
          flakeModules = publicFlakeModules;

          # For backward compat
          flakeModule = flakeModules.default;
          overlays = import ./overlays { inherit (self) inputs outputs; };
          templates = import ./templates;

          # All home configs dynamically generated
          homeConfigurations = self.lib.neusisOS.mkHomeConfigurations {
            machinesRegistry = import ./machines/registry.nix {
              inherit lib;
              nixpkgs = self.inputs.nixpkgs;
              overlays = self.outputs.overlays;
            };
            userConfig = import ./users/all.nix { inherit self; };
            specialArgs = { inherit (self) inputs outputs; };
          };

        };

      }
    );
}

# PerSystem template

# perSystem =
#   {
#     config,
#     pkgs,
#     inputs',
#     self',
#     system,
#     ...
#   }:
#   {
#
#   };
