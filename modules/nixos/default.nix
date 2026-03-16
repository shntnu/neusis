{
  outputs,
  ...
}:

{
  cslab-infrastructure = import ./cslab-infrastructure.nix;
  sunshine = import ./sunshine.nix;
  monitoring = import ./monitoring.nix;
  tailscale = import ./tailscale.nix;
  xilinx = import ./xilinx.nix { inherit outputs; };
}
