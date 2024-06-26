{ pkgs, config, lib, ...}:
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
