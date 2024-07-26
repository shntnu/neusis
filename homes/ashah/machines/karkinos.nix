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
      username = "Adit Shah";
      userEmail = "aditshah00@gmail.com";
      id_ed25519_pub = builtins.readFile ../id_rsa.pub;
    })
    ../../common/browsers
    ../../common/network
    ../../common/misc
    ../../common/secrets
  ];
}
