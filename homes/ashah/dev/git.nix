{ config, ... }:
{
  home.file.".ssh/allowed_signers".text =
    "* ${builtins.readFile ../id_rsa.pub}";
  programs.git = {
    enable = true;
    userName = "Adit Shah";
    userEmail = "aditshah00@gmail.com";
    extraConfig = {
        # Sign all commits using ssh key
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        user.signingkey = "~/.ssh/id_rsa.pub";
      };
  };
}
