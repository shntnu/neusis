{ pkgs, inputs, ... }:
let
  jail = inputs.jail-nix.lib.init pkgs;
  opencode_pkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  # Common packages available to both agents
  commonPkgs = with pkgs; [
    bashInteractive
    curl
    wget
    jq
    git
    which
    ripgrep
    gnugrep
    gawkInteractive
    ps
    findutils
    gzip
    unzip
    gnutar
    diffutils
    nh
  ];
  # Common sandbox options shared by both agents
  commonJailOptions = with jail.combinators; [
    network
    time-zone
    no-new-session
    mount-cwd
  ];
  makeJailedOpencode =
    {
      extraPkgs ? [ ],
    }:
    jail "opencode" opencode_pkg (
      with jail.combinators;
      (
        commonJailOptions
        ++ [
          # Give it a safe spot for its own config and cache.
          # This also lets it remember things between sessions.
          (readwrite (noescape "~/.config/opencode"))
          (readwrite (noescape "~/.local/share/opencode"))
          (readwrite (noescape "~/.local/state/opencode"))

          (add-pkg-deps commonPkgs)
          (add-pkg-deps extraPkgs)
        ]
      )
    );
  jailed_opencode = makeJailedOpencode { };
  custom_opencode_pkg = if pkgs.stdenv.isLinux then jailed_opencode else pkgs.opencode;
in
{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.agent-deck
  ];
  programs.opencode = {
    package = custom_opencode_pkg;
    enable = true;
    settings = { };

  };

}
