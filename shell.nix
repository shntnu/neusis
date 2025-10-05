# Shell for bootstrapping flake-enabled nix and other tooling
{
  pkgs ?
    # If pkgs is not defined, instantiate nixpkgs from locked commit
    let
      lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
      nixpkgs = fetchTarball {
        url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
        sha256 = lock.narHash;
      };
    in
    import nixpkgs { overlays = [ ]; },
  inputs,
  ...
}:
let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";
    nativeBuildInputs =
      with pkgs;
      [
        home-manager
        git
        uv
        nixos-anywhere
        pkgs-unstable.claude-code

        inputs.agenix.packages.${system}.default
        ssh-to-age
        gnupg
        age

        # Documentation tools
        markdownlint-cli
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        # Linux-only tools for NixOS deployment
        disko
      ];
  };
}
