{ config, ... }:
{
  home.file.".ssh/allowed_signers".text =
    "* ${builtins.readFile ../id_ed25519.pub}";
  programs.git = {
    enable = true;
    userName = "Ankur Kumar";
    userEmail = "ank@leoank.me";
    extraConfig = {
        # Sign all commits using ssh key
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signingkey = "~/.ssh/id_ed25519.pub";
      };
  };
}
