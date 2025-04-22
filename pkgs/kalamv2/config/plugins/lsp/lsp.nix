{
  plugins = {
    lsp-signature.enable = true;

    lsp = {
      enable = true;
      servers.typos_lsp.enable = true;
    };
    lint.enable = true;
  };

}
