{ pkgs, ... }:
{
  home = {
    username = "blye";
    homeDirectory = "/home/blye";

    # Start small; add personal tools here as needed.
    packages = with pkgs; [
      curl
      wget
      nano
      tmux
      htop
      jq
      ripgrep
      python3
      uv
    ];
  };

  programs = {
    zsh.enable = true;
    git = {
      enable = true;
      settings = {
        user = {
          name = "Bryan Lye";
          email = "bryan.lye@unsw.edu.au";
        };
        init.defaultBranch = "main";
      };
    };
  };
}
