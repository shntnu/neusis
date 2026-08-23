{ pkgs, inputs, ... }:
  {
    home = {
      username = "rshen";
      homeDirectory = "/home/rshen";

      packages = with pkgs; [
        duckdb
        jq
        wget # fetch stuff
        ps # processes
        killall # kill all the processes by name
        screen # ssh in and out of a server
        cmake # c compiler
        rsync # sync data
        zip
        unzip # extract zips
        # monitor
        btop # nicer btop

        # python
        #python310 # the standard python
        poetry # python package management
        pixi # package manager

        # dev tooling
        inputs.claude-code-rshen.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
        gitleaks # secret scanner for local pre-commit/pre-push hooks
      ];
    };
  }
