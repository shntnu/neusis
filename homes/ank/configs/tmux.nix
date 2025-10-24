{ pkgs, ... }:
{
  programs.sesh = {
    enable = true;
    tmuxKey = "s";
  };
  programs.fzf.tmux.enableShellIntegration = true;
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    mouse = true;
    #sensibleOnTop = true;
    prefix = "C-b";
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.vim-tmux-navigator;
        extraConfig = ''
          setw -g mode-keys vi
          bind-key h select-pane -L
          bind-key j select-pane -D
          bind-key k select-pane -U
          bind-key l select-pane -R
        '';
      }
      # {
      #   plugin = tmuxPlugins.catppuccin;
      #   extraConfig = ''
      #     set -g @catppuccin_flavour 'frappe'
      #     set -g @catppuccin_window_tabs_enabled on
      #     set -g @catppuccin_date_time "%H:%M"
      #   '';
      # }
      # {
      #   plugin = tmuxPlugins.dracula;
      #   extraConfig = ''
      #     set -g status-position top
      #     set -g @dracula-plugins "cpu-usage gpu-usage ram-usage"
      #     set -g @dracula-border-contrast true
      #     set -g @dracula-show-powerline true
      #     set -g @dracula-transparent-powerline-bg true
      #     set -g @dracula-show-flags false
      #     set -g @dracula-show-left-icon "#h | #S"
      #     set -g @dracula-no-battery-label false
      #     set -g @dracula-colors "
      #       foreground='#4d4d4c'
      #       background='#ffffff'
      #       highlight='#d6d6d6'
      #       status_line='#efefef'
      #       comment='#8e908c'
      #       red='#c82829'
      #       orange='#f5871f'
      #       yellow='#eab700'
      #       green='#718c00'
      #       aqua='#3e999f'
      #       blue='#4271ae'
      #       purple='#8959a8'
      #       pane='#efefef'
      #     "
      #   '';
      # }
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-boot 'on'
          set -g @continuum-save-interval '10'
          set -g @continuum-boot-options 'wezterm'
        '';
      }
      tmuxPlugins.better-mouse-mode
    ];
    extraConfig = ''
      set -gu default-command
      set -g default-shell "$SHELL"
      set -gq allow-passthrough on
      set -sg terminal-overrides ",*:RGB"
    '';
  };
}
