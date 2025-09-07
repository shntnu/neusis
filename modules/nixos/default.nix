{
  outputs,
  ...
}:

{
  sunshine = import ./sunshine.nix;
  monitoring = import ./monitoring.nix;
  xilinx = import ./xilinx.nix { inherit outputs; };
}
