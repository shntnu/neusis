{ outputs, ... }:
{
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
  };

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
  
  # SSH Agent configuration for ALL users - automatically manages encrypted SSH keys
  services.ssh-agent.enable = true;
  
  # Auto-add default SSH key on shell startup (prompts for passphrase once per session)
  programs.bash.initExtra = ''
    # Add SSH key to agent if not already added
    if [ -f ~/.ssh/id_ed25519 ]; then
      if ! ssh-add -l &>/dev/null || ! ssh-add -l | grep -q "id_ed25519"; then
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
      fi
    fi
  '';
  
  programs.zsh.initContent = ''
    # Add SSH key to agent if not already added
    if [ -f ~/.ssh/id_ed25519 ]; then
      if ! ssh-add -l &>/dev/null || ! ssh-add -l | grep -q "id_ed25519"; then
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
      fi
    fi
  '';
}
