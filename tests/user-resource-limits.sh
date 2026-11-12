#!/usr/bin/env bash
set -euo pipefail
repository=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
nix eval --json --file "$repository/tests/user-resource-limits.nix" |
  jq -e 'all(.[]; . == true)' >/dev/null
nix eval --json --no-write-lock-file "path:$repository#nixosConfigurations" --apply 'systems:
  builtins.mapAttrs (name: system: let config = system.config; in {
    uid = config.users.users.jrietdij.uid or null;
    limits = config.systemd.slices.user-1008.sliceConfig or null;
    unit = config.systemd.units."user-1008.slice".text or "";
  }) (builtins.intersectAttrs { oppy = null; spirit = null; karkinos = null; } systems)
' | jq -e '
  .oppy.uid == 1008 and
  .oppy.limits.MemoryHigh == "512G" and
  .oppy.limits.MemoryMax == "768G" and
  .oppy.limits.TasksMax == 4096 and
  (.oppy.unit | contains("MemoryHigh=512G")) and
  (.oppy.unit | contains("MemoryMax=768G")) and
  (.oppy.unit | contains("TasksMax=4096")) and
  .spirit.uid == null and .spirit.limits == null and
  .karkinos.uid == null and .karkinos.limits == null
' >/dev/null
printf 'UID selection, generated slice limits and physical-host isolation passed.\n'
