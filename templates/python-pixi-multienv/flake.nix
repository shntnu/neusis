{
  description = "Multi-Environment Demo: Handling Incompatible Dependencies with Pixi on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pixi
            linuxPackages.nvidia_x11
          ];

          shellHook = ''
            echo "Pixi Multi-Environment Development"
            echo ""
            echo "Problem: RAPIDS needs numpy ≥2, jump-smiles needs numpy <2"
            echo "Solution: Separate pixi environments"
            echo ""
            echo "Usage:"
            echo "  pixi shell -e rapids  # GPU/RAPIDS (numpy 2.x)"
            echo "  pixi shell -e smiles  # Chemical standardization (numpy 1.x)"
          '';

          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [
            pkgs.linuxPackages.nvidia_x11
          ]}";
        };
      });
}
