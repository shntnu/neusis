{ pkgs, ... }:
{
  home = {
    username = "amunoz";
    homeDirectory = "/home/amunoz";

    packages = with pkgs; [
      autoconf
      automake
      autotools-language-server # make
      bc # calculator
      btop-cuda # nicer top
      cargo # rust packages
      clang # c language
      clang-tools # tools for c language
      cmake # c compiler
      devenv
      difftastic # better diffs
      direnv # Per-project isolated environment
      dua # better du
      duckdb
      dust # interactive du in tust
      emacs
      emacs-all-the-icons-fonts
      fd # faster find
      ffmpeg # video processing needs
      fish
      fishPlugins.async-prompt
      fishPlugins.autopair
      fishPlugins.pure
      fontconfig # Needed for napari
      fzf # fuzzy finder
      gawk
      git
      gnumake # Necessary for emacs' vterm
      gnumeric
      gnuplot # no-fuss plotting
      gnused # The one and only sed
      gnutar # The one and only tar
      gprof2dot
      graphicsmagick # imagemagick (+speed, -features) alternative
      graphviz
      haskellPackages.xml-to-json-fast
      http-server
      hugo # blogging
      imagemagick # image processing
      inkscape # Graphics editing
      jq # process json
      killall # kill all the processes by name
      kitty
      lemminx # xml
      libtool # Necessary for emacs' vterm
      lsof # Files and their processes
      ltex-ls # language tool LSP for latex and org-mode
      luajitPackages.fennel # lua in fennel
      magic-wormhole # easy sharing
      marksman # markdown
      mawk # faster awk
      mermaid-cli # text to diagrams
      mpv # video player
      nil # Nix
      nix-index # locate packages that provide a certain file
      nix-output-monitor
      nix-search-cli # find nix packages
      nixfmt-rfc-style # Nix formatting (for nixpkgs)
      nixfmt-tree # Format entire directories of nix
      nodePackages.bash-language-server # bash
      pandoc # Convert between formats
      parallel # GNU parallel
      pdftk
      pigz # threaded gunzip
      pinta # Basic image editing
      podman # for container needs
      ps # processes
      qrtool # encode and decode qr codes
      ripgrep # faster grep in rust
      rsync # sync data
      ruff # python
      rustc # rust compiler
      screen # ssh in and out of a server
      semgrep # generalistic semantic grep
      shellcheck
      shfmt
      shiori # download whole html websites
      tldr # quick explanations
      tree
      unzip # extract zips
      uv
      wezterm
      wget # fetch stuff
      xclip # clipboard manipulation tool
      yaml-language-server # yaml
      zip
      zotero
    ];
  };
}
