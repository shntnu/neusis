{ pkgs, config, lib, ...}:
let
  astroank_src = pkgs.fetchFromGitHub {
    owner = "leoank";
    repo = "astroank";
    rev = "cc5e103b88554e3d2d6e158ea9b6ae2ed3ed2b81";
    sha256 = "sha256-QC54o9HJL5bKdJmCInvZjN9agEzKQoNKm6TbsLbX8Ys=";
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

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
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
      ps.luarocks
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
