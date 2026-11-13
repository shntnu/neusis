#!/usr/bin/env bash
set -euo pipefail
repository=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
nix eval --json --no-write-lock-file "path:$repository#nixosConfigurations" --apply 'systems:
  builtins.mapAttrs (name: system: let
    c = system.config;
    u = c.users.users.blye;
    h = c.home-manager.users.blye;
  in {
    normal = u.isNormalUser;
    description = u.description;
    shell = u.shell.pname;
    home = u.home;
    groups = u.extraGroups;
    keys = map builtins.readFile u.openssh.authorizedKeys.keyFiles;
    packages = map (p: p.pname or p.name) h.home.packages;
    username = h.home.username;
    homeDirectory = h.home.homeDirectory;
    zsh = h.programs.zsh.enable;
    git = h.programs.git.settings;
  }) (builtins.intersectAttrs { oppy = null; spirit = null; } systems)
' | jq -e '
  .oppy.normal == true and
  .oppy.description == "Bryan Lye" and .oppy.shell == "zsh" and
  .oppy.home == "/home/blye" and
  (.oppy.groups | index("wheel") | not) and
  (.oppy.groups | sort) == (.spirit.groups | sort) and
  .oppy.keys == .spirit.keys and (.oppy.keys | length) == 1 and
  .oppy.username == "blye" and .oppy.homeDirectory == "/home/blye" and
  .oppy.zsh == true and .oppy.git == .spirit.git and
  (.oppy.packages | sort) == (.spirit.packages | sort)
' >/dev/null
nix eval --json --no-write-lock-file "path:$repository#homeConfigurations" --apply 'homes:
  builtins.hasAttr "blye@oppy" homes && builtins.hasAttr "blye@spirit" homes
' | jq -e '. == true' >/dev/null
printf 'Bryan: matching Oppy/Spirit account, key, groups, tools and home profiles passed.\n'
