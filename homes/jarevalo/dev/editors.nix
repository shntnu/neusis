{ pkgs, config, lib, ...}:
let
  astronvim_src = pkgs.fetchFromGitHub {
    owner = "AstroNvim";
    repo = "AstroNvim";
    rev = "d36af2f75369e3621312c87bd0e377e7d562fc72";
    sha256 = "sha256-1nfMx9XaTOfuz1IlvepJdEfrX539RRVN5RXzUR00tfk=";
  };
  astroank_src = pkgs.fetchFromGitHub {
    owner = "leoank";
    repo = "astroank";
    rev = "fe3873a966730a8f1cb97a6fe7092a1fa5ef442c";
    sha256 = "sha256-hOLawys+1FJbRpJ5pSL945TYf62nog+Dsp+mnNc7NMI=";
  };
in
{
  home.packages = with pkgs; [
    xclip
    ripgrep
    lazygit
    gdu
    bottom
    yazi
    python3
    nodejs_21
    nerdfonts
    meslo-lgs-nf
    deno
    cargo
    rustc
    cmake
    clang
    unzip
    sioyek
    nvitop
    htop
    fd
    imagemagick
  ];

  programs.direnv.enable = true;
  programs.neovim = {
    enable = true;
    # whatever other neovim configuration you have
    extraPackages = with pkgs; [
      # ... other packages
      imagemagick # for image rendering
    ];
    extraLuaPackages = ps: [
      # ... other lua packages
      ps.magick # for image rendering
    ];
    extraPython3Packages = ps: with ps; [
      # ... other python packages
      pynvim
      jupyter-client
      cairosvg # for image rendering
      pnglatex # for image rendering
      plotly # for image rendering
      pyperclip
    ];
  };
  
  xdg.configFile."nvim" = {
    source = astronvim_src;
    recursive = true;
  };

  xdg.configFile."nvim/lua/user/" = {
    source = astroank_src;
    recursive = true;
  };

  programs.gh.enable = true;
  programs.thefuck.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake .#karkinos -v";
      n = "nvim";
      ns = "nix search nixpkgs";
    };
    initExtra = ''
      function nz() {
        $(zoxide query $1) && nvim .
      }

      function nx() {
        nix-shell -p $1
      }

      bindkey '^I' complete-word
      bindkey '^[[Z' autosuggest-accept
    '';
    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "gh" "thefuck" ];
      theme = "fino-time";
    };
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

}
