{ pkgs, ...}:
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
    rev = "fa43a94794fe504ba267b500e559ef02704b2b1c";
    sha256 = "sha256-B09lzU5wWZ6prxNVjWGm3kz3/A/00APcZ8O26XYNkL0=";
  };
in
{
  home.packages = with pkgs; [
    neovim 
    ripgrep
    lazygit
    gdu
    bottom
    ranger
    python3
    nodejs_21
    nerdfonts
    meslo-lgs-nf
    zoxide
    deno
    cargo
    rustc
    cmake
    clang
    unzip
    sioyek
  ];

  xdg.configFile."nvim" = {
    source = astronvim_src;
    recursive = true;
  };

  xdg.configFile."nvim/lua/user/".source = astroank_src;
}
