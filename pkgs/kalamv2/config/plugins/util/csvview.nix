{ mpkgs, ... }:
{
  plugins.csvview = {
    package = mpkgs.vimPlugins.csvview-nvim;
    enable = true;
    settings = {
      parser.async_chunksize = 100;
      view = {
        spacing = 4;
        display_mode = "border";
      };
    };
  };
}
