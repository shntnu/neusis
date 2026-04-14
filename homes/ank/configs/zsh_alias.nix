{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    zprof.enable = false;
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "gh"
        "globalias"
      ];
    };
    shellGlobalAliases = {
      G = "| grep --color=auto -i -n -c";
    };
    shellAliases = {
      oc = "opencode";
      ll = "eza -lah --color-scale=all --hyperlink";
      lt = "eza -l --git --git-repos --tree --level=2 --color-scale=all --hyperlink";
      n = "nvim";
      nvt = "nvim +terminal";
      ns = "nix search nixpkgs";
      cat = "bat";
      df = "duf";
    };

    #https://discourse.nixos.org/t/terminal-zsh-performance-issue-under-home-manager-help/55798/11
    completionInit = ''
      autoload -Uz compinit
      fpath=(''${(ou)fpath}) # Stable fpath order hence consistent cache hit.
      if [[ ! -s ''${ZDOTDIR:-$HOME}/.zcompdump || \
            /run/current-system/sw -nt ''${ZDOTDIR:-$HOME}/.zcompdump ]]; then
        compinit
        zcompile ''${ZDOTDIR:-$HOME}/.zcompdump 2>/dev/null
      else
        compinit -C
      fi
    '';
    initContent = ''
      function nz() {
        cd $(zoxide query $1) && nvim
      }
      function nx() {
        nix-shell -p $@
      }
      function nxp() {
        nix-shell -p "python3.withPackages(p: with p; [$@])"
      }
      function nxpc() {
        nix-shell --arg config "{ allowUnfree = true; cudaSupport = true; }" -p "python3.withPackages(p: with p; [$@])"
      }

      export EDITOR=nvim
      export TERM=xterm
    '';

  };
}
