{
  description = "Neusis: Crafting systems";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable"; 

    # disko

    inputs.disko.url = "github:nix-community/disko";
    inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

    # VS Code
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix.url = "github:ryantm/agenix";

    hardware.url = "github:nixos/nixos-hardware";

    nix-colors.url = "github:misterio77/nix-colors";

    nh = {
      url = "github:viperml/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    # nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    # nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";

    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    superfile = {
      url = "github:yorukot/superfile";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs systems (system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    });
  in {
    inherit lib;

    nixosModules = import ./modules/nixos {inherit inputs outputs;};
    homeManagerModules = import ./modules/home-manager;

    # templates = import ./templates;
    overlays = import ./overlays { inherit inputs outputs; };
    # packages = import ./pkgs;
    
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs inputs;});
    formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      karkinos = lib.nixosSystem {
        modules = [ ./machines/karkinos ];
        specialArgs = {inherit inputs outputs; };
      };

      chiral = lib.nixosSystem {
        modules = [ ./machines/chiral ];
        specialArgs = {inherit inputs outputs; };
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "ank@karkinos" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs; };
        # > Our main home-manager configuration file <
        modules = [ ./homes/ank/karkinos.nix ];
      };

      "ank@chiral" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs; };
        # > Our main home-manager configuration file <
        modules = [ ./homes/ank/chiral.nix ];
      };
    };
  };
}
