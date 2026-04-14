{ pkgs, ... }:
{
  # https://scottspence.com/posts/speeding-up-my-zsh-shell#fixing-the-completion-system-3076--10
  programs.zsh.initContent = pkgs.lib.mkMerge [
  ];
}
