let
  users = import ../lib/neusisOS.nix {
    inputs = { };
    lib.optionals = condition: values: if condition then values else [ ];
  };
  regular = {
    username = "example";
    fullName = "Example";
    shell = "zsh";
    sshKeys = [ ];
  };
  uidFor =
    machineName: extra:
    let
      modules = users.mkDynamicUsers {
        inherit machineName;
        userConfig = {
          admins = [ ];
          guests = [ ];
          regulars = [ (regular // extra) ];
        };
      };
      evaluated = (builtins.head modules) {
        config = { };
        pkgs.zsh = "zsh";
      };
    in
    evaluated.users.users.example.uid;
  limitsFor =
    uid:
    import ../machines/oppy/user-resource-limits.nix {
      config.users.users.jrietdij.uid = uid;
    };
in
{
  automaticUidUnchanged = uidFor "oppy" { } == null;
  explicitUidSupported = uidFor "oppy" { uid = 1234; } == 1234;
  machineUidWins =
    uidFor "oppy" {
      uid = 1234;
      uids.oppy = 1008;
    } == 1008;
  otherMachineAutomatic = uidFor "spirit" { uids.oppy = 1008; } == null;
  otherMachineFallback =
    uidFor "spirit" {
      uid = 1234;
      uids.oppy = 1008;
    } == 1234;
  expectedUidAccepted = (builtins.head (limitsFor 1008).assertions).assertion;
  wrongUidRejected = !(builtins.head (limitsFor 1009).assertions).assertion;
  correctLimits =
    (limitsFor 1008).systemd.slices.user-1008.sliceConfig == {
      MemoryHigh = "512G";
      MemoryMax = "768G";
      TasksMax = 4096;
    };
}
