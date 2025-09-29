{
  pkgs,
  mpkgs,
  ...
}:
{

  config = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "";
        src = pkgs.fetchFromGitHub {
          owner = "NStefan002";
          repo = "screenkey.nvim";
          rev = "16390931d847b1d5d77098daccac4e55654ac9e2";
          hash = "sha256-EGyIkWcQbCurkBbeHpXvQAKRTovUiNx1xqtXmQba8Gg=";
        };
      })
      #avante-nvim
      #mpkgs.vimPlugins.blink-cmp-avante
      mpkgs.vimPlugins.llm-nvim
    ];

    extraConfigLua = ''
      local screenkey = require("screenkey")

      -- setup with default config
      screenkey.setup()

      -- create a toggle function
      local function toggleScreenKey()
          vim.cmd("Screenkey toggle")
      end

      --- add keymap for toggle screenkey
      vim.keymap.set("n", "<leader>tsk", toggleScreenKey, { desc = "[T]oggle [S]creen[K]ey" })


      --- setup llm-nvim
      -- require("llm").setup({
      --   model = "gpt-oss:latest",
      --   backend = "ollama",
      --   url = "http://karkinos:11434",
      --   context_window = 128000,
      --   accept_keymap = "<C-l>",
      --   dismiss_keymap = "<C-e>",
      --   lsp = {
      --     bin_path = "${pkgs.llm-ls}/bin/llm-ls"
      --   },
      -- })
    '';
  };
}
