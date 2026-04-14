{
  programs.zsh = {
    enable = true;
    shellAliases = {
      oc = "opencode";
    };
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

      bindkey '^I' complete-word
      bindkey '^[[Z' autosuggest-accept
      export EDITOR=nvim
      export TERM=xterm
    '';
  };
}
