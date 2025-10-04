{
  description = "2025 Best Practice: Pure Pixi for GPU/RAPIDS Development on NixOS";

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
            echo "Pixi GPU Development Environment"
          '';

          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [
            pkgs.linuxPackages.nvidia_x11
          ]}";
        };
      });
}
