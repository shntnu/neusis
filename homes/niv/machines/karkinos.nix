{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ../home.nix
    ../../common/home_manager.nix
    ../../common/dev
    (import ../../common/dev/editors.nix {
      inherit pkgs config inputs;
      enableNvim = true;
      enableAstro = true;
    })
    (import ../../common/dev/git.nix {
      username = "Niveditha";
      userEmail = "nivsiyer@stanford.edu";
      id_ed25519_pub = builtins.readFile ../id_ed25519.pub;
    })
    ../../common/secrets
    ../../common/browsers
    ../../common/network
    ../../common/misc
    ../../common/gpu_tools.nix
  ];
}
