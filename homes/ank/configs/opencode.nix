{ ... }:
{
  # Add opencode config
  xdg.configFile."opencode/opencode.json" = {
    source = ./opencode.json;
    recursive = true;
  };
}
