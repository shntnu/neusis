{ config, ... }:
let
  uid = config.users.users.jrietdij.uid;
in
{
  assertions = [
    {
      assertion = uid == 1008;
      message = "Oppy resource limits require jrietdij's verified UID 1008 (users/cslab.nix).";
    }
  ];

  # Aggregate limits for normal login sessions and user services. TasksMax
  # counts threads as well as processes. MemoryMax causes cgroup-local OOM
  # kills if reclaim fails; do not configure whole-user OOM group killing.
  systemd.slices."user-${toString uid}" = {
    description = "Resource containment for jrietdij on Oppy";
    sliceConfig = {
      MemoryHigh = "512G";
      MemoryMax = "768G";
      TasksMax = 4096;
    };
  };
}
