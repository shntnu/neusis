{ pkgs, ... }:
{
  home = {
    username = "shsingh";
    homeDirectory = "/home/shsingh";

    packages = with pkgs; [
      # Data tools
      duckdb
      jq
      yq-go  # YAML processor
      
      # Development tools
      gh  # GitHub CLI
      lazygit  # Terminal UI for git
      delta  # Better git diff
      bat  # Better cat with syntax highlighting
      eza  # Modern ls replacement
      fd  # Better find
      ripgrep  # Fast grep
      fzf  # Fuzzy finder
      zoxide  # Smart cd command
      
      # System monitoring
      htop
      btop  # Better htop
      ncdu  # Disk usage analyzer
      duf  # Better df
      
      # Network tools
      curl
      wget
      httpie  # Better curl for APIs
      mtr  # Network diagnostic tool
      
      # File management
      tree
      ranger  # Terminal file manager
      yazi  # Modern terminal file manager
      
      # Text processing
      neovim
      micro  # Simple modern editor
      
      # Archive tools
      unzip
      zip
      p7zip
      
      # Misc utilities
      tldr  # Simplified man pages
      direnv  # Directory-specific environments
      tmux  # Terminal multiplexer
      screen
      starship  # Modern shell prompt
    ];
  };
}
