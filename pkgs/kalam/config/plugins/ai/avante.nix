{
  plugins.avante = {
    enable = true;
    settings = {
      diff = {
        autojump = true;
        debug = false;
        list_opener = "copen";
      };
      highlights = {
        diff = {
          current = "DiffText";
          incoming = "DiffAdd";
        };
      };
      hints = {
        enabled = true;
      };
      mappings = {
        diff = {
          both = "cb";
          next = "]x";
          none = "c0";
          ours = "co";
          prev = "[x";
          theirs = "tc";
        };
      };
      provider = "ollama";
      vendors = {
        ollama = {
          __inherited_from = "openai";
          api_key_name = "";
          endpoint = "karkinos:11434/v1";
          model = "llama3.3:latest";
          local = true;
        };
      };

      windows = {
        sidebar_header = {
          align = "center";
          rounded = true;
        };
        width = 30;
        wrap = true;
      };
    };

  };
  plugins.render-markdown = {
    enable = true;
    settings = {
      file_types = [
        "Avante"
      ];
    };
  };
}
