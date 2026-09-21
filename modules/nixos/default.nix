{
  outputs,
  ...
}:

{
  cslab-infrastructure = import ./cslab-infrastructure.nix;
  cslab-monitoring = import ./cslab-monitoring.nix;
  safe-switch = import ./safe-switch.nix;
  sunshine = import ./sunshine.nix;
  monitoring = import ./monitoring.nix;
  tailscale = import ./tailscale.nix;
  zfs = import ./zfs.nix;
  xilinx = import ./xilinx.nix { inherit outputs; };
}
