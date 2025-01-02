{
  plugins.toggleterm = {
    enable = true;
    settings = {
      size = ''
        function(term)
          if term.direction == "horizontal" then
            return 30
        elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end
      '';
      open_mapping = "[[<c-\>]]";
      auto_scroll = false;
      hide_numbers = false;
      shade_terminals = true;
      start_in_insert = false;
      terminal_mappings = true;
      persist_mode = true;
      insert_mappings = true;
      close_on_exit = true;
      shell = "zsh";
      direction = "horizontal"; # 'vertical' | 'horizontal' | 'tab' | 'float'
      float_opts = {
        border = "single"; # 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
        width = 80;
        height = 20;
        winblend = 0;
      };
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<C-\\>";
      action = "<cmd>ToggleTerm<cr>";
      options.desc = "Open/Close Terminal";
    }
    {
      mode = "t";
      key = "<C-\\>";
      action = "<cmd>ToggleTerm<cr>";
      options.desc = "Open/Close Terminal";
    }
    {
      mode = "t";
      key = "<esc>";
      action = "<C-\\><C-n>";
      options.desc = "Escape to normal mode";
    }
    {
      mode = "t";
      key = "<C-h>";
      action = "<cmd>wincmd h<cr>";
      options.desc = "Go to Left window";
    }
    {
      mode = "t";
      key = "<C-l>";
      action = "<cmd>wincmd l<cr>";
      options.desc = "Go to Right window";
    }
    {
      mode = "t";
      key = "<C-j>";
      action = "<cmd>wincmd k<cr>";
      options.desc = "Go to Up window";
    }
    {
      mode = "t";
      key = "<C-k>";
      action = "<cmd>wincmd j<cr>";
      options.desc = "Go to Down window";
    }
  ];
}
