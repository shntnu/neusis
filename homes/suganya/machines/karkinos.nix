{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../home.nix
    ../../common/home_manager.nix
    ../../common/dev
    (import ../../common/dev/editors.nix {
      inherit pkgs config;
      enableNvim = true;
      enableAstro = true;
    })
    (import ../../common/dev/git.nix {
      username = "Suganya Sivagurunathan";
      userEmail = "suganya.nathan@gmail.com";
      id_ed25519_pub = builtins.readFile ../id_ed25519.pub;
    })
    ../../common/browsers
    ../../common/network
    ../../common/misc
    ../../common/secrets
  ];
}
