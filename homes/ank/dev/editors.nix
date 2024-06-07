{ pkgs, config, inputs, ...}:
let
  astroank_src = pkgs.fetchFromGitHub {
    owner = "leoank";
    repo = "astroank";
    rev = "31a801a58273c93e382fb12c78b9643f8f10fd07";
    sha256 = "sha256-a/AsZOWLH8m3VedxukhI3Z0sRli8K0eoT9+cQ7ZMKLM=";
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
    clang-tools
    unzip
    sioyek
    nvitop
    htop
    fd
    imagemagick
    zellij
    inputs.superfile.packages.${pkgs.system}.default
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

  programs.gh =  {
    enable = true;
    extensions = [ pkgs.gh-dash ];
  };
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
