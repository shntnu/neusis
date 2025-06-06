{
  imports = [
    ./ai/codeium.nix
    #./ai/avante.nix

    ./completion/cmp.nix
    ./completion/lspkind.nix

    ./debug/dap.nix

    ./editor/neotree.nix
    ./editor/undotree.nix
    ./editor/whichkey.nix
    ./editor/yazi.nix
    ./editor/oil.nix

    ./theme
    ./luasnip
    ./telescope

    ./git/gitsigns.nix
    ./git/neogit.nix
    #./git/git-worktree.nix

    ./lsp/conform.nix
    ./lsp/fidget.nix
    ./lsp/lsp.nix
    ./lsp/lspsaga.nix
    ./lsp/trouble.nix

    ./lang/cpp.nix
    ./lang/css.nix
    ./lang/docker.nix
    ./lang/html.nix
    ./lang/json.nix
    ./lang/lua.nix
    ./lang/markdown.nix
    ./lang/nix.nix
    ./lang/python.nix
    ./lang/shell.nix
    ./lang/typescript.nix
    ./lang/yaml.nix
    ./lang/tex.nix

    ./treesitter/treesitter.nix
    ./treesitter/treesitter-textobjects.nix

    ./ui/alpha.nix
    ./ui/bufferline.nix
    ./ui/general.nix
    ./ui/flash.nix
    ./ui/indent-blankline.nix
    ./ui/lualine.nix
    ./ui/noice.nix
    ./ui/notify.nix
    ./ui/nui.nix
    ./ui/precognition.nix
    ./ui/toggleterm.nix
    ./ui/ufo.nix

    ./util/colorizer.nix
    ./util/debugprint.nix
    ./util/kulala.nix
    ./util/mini.nix
    ./util/nvim-autopairs.nix
    ./util/nvim-surround.nix
    ./util/plenary.nix
    ./util/persistence.nix
    ./util/project-nvim.nix
    ./util/snacks.nix
  ];
}
