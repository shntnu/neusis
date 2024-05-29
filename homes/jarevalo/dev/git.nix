{ config, ... }:
{
  home.file.".ssh/allowed_signers".text =
    "* ${builtins.readFile ../id_ed25519.pub}";
  programs.git = {
    enable = true;
    userName = "John Arevalo";
    userEmail = "johnarevalo@gmail.com";
    extraConfig = {
        # Sign all commits using ssh key
        pull.ff = "only";
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        user.signingkey = "~/.ssh/id_ed25519.pub";
      };
  };
}
