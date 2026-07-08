{
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  # FHS compatibility
  programs.nix-ld.enable = true;

  # Required to make theme related things work
  programs.dconf.enable = true;

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  # Base system packages shared across all machines
  environment.systemPackages = [
    pkgs.vim
    pkgs.dive
    pkgs.podman-tui
    # System-wide home-manager CLI. Pulled from the flake input so its
    # version tracks the same nixpkgs channel neusis pins, and users can
    # run `home-manager switch --flake github:shntnu/neusis#<user>@<host>`
    # without a per-user install step.
    inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Ensure terminfo entries for modern terminals (ghostty, kitty, etc.)
  # are available so SSH sessions from these terminals work correctly
  environment.enableAllTerminfo = true;

  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;
  programs.fish.enable = true;
}
