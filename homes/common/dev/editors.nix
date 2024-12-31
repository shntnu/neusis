{
  pkgs,
  config,
  inputs,
  enableNvim ? false,
  enableAstro ? false,
  ...
}:
let
  astroank_src = inputs.astroank;
  pdf_viewer = if pkgs.stdenv.isDarwin then [ ] else [ pkgs.sioyek ]; # sioyek is not building on darwin
in
{
  home.packages =
    with pkgs;
    [
      xclip
      ripgrep
      lazygit
      gdu
      bottom
      yazi
      python3
      nodejs_22
      nerdfonts
      meslo-lgs-nf
      deno
      cargo
      rustc
      cmake
      clang
      clang-tools
      unzip
      htop
      fd
      imagemagick
      zellij
      lua51Packages.lua
      lua51Packages.luarocks
      fzf
      ninja
      gnumake
      texliveFull
      wget
    ]
    ++ pdf_viewer;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.neovim =
    if enableNvim then
      {
        enable = true;
        package = pkgs.unstable.neovim-unwrapped;
        # whatever other neovim configuration you have
        extraPackages = with pkgs; [
          # ... other packages
          imagemagick # for image rendering
          zlib
          sqlite
        ];
        extraLuaPackages = ps: [
          # ... other lua packages
          ps.magick # for image rendering
          ps.luarocks
        ];
        extraPython3Packages =
          ps: with ps; [
            # ... other python packages
            pynvim
            jupyter-client
            cairosvg # for image rendering
            pnglatex # for image rendering
            plotly # for image rendering
            # kaleido # molten
            nbformat # molten
            pyperclip
          ];
      }
    else
      { enable = false; };

  xdg.configFile =
    if enableAstro then
      {
        "nvim" = {
          source = astroank_src;
          recursive = true;
        };
      }
    else
      { };

  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-dash ];
  };
  programs.thefuck.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      n = "nvim";
      ns = "nix search nixpkgs";
    };
    initExtra = ''
      function update() {
        sudo nixos-rebuild switch --flake .#$1 -v
      }

      function nz() {
        cd $(zoxide query $1) && nvim
      }

      function nx() {
        nix-shell -p $@
      }

      bindkey '^I' complete-word
      bindkey '^[[Z' autosuggest-accept
      export EDITOR=nvim
      export TERM=xterm
    '';
    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "gh"
        "thefuck"
      ];
      theme = "fino-time";
    };
  };
  programs.starship.enable = true;
  programs.fzf.enable = true;
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
