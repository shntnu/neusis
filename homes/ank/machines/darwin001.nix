{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../../common/home_manager.nix
    ../../common/dev
    ../../common/dev/kalam.nix
    (import ../../common/dev/editors.nix {
      inherit pkgs config inputs;
      enableNvim = false;
      enableAstro = false;
    })
    (import ../../common/dev/git.nix {
      username = "Ankur Kumar";
      userEmail = "ank@leoank.me";
      id_ed25519_pub = builtins.readFile ../id_ed25519.pub;
    })
  ];

  home.packages = with pkgs; [
    dockutil
    starship
  ];
}
