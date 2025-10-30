{
  outputs,
  inputs,
  ...
}:
{
  imports = [
    outputs.nixosModules.monitoring
    outputs.nixosModules.sunshine
    inputs.nixos-generators.nixosModules.all-formats
  ];

  # Enable monitoring
  neusis.services.monitoring.enable = true;

  # Enable ZFS auto-snapshots
  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 4;   # Keep 4 snapshots (15 min intervals)k
    hourly = 24;    # Keep 24 snapshots
    daily = 31;     # Keep 31 snapshots
    weekly = 8;     # Keep 8 snapshots
    monthly = 12;   # Keep 12 snapshots
  };

  # Add udev rules and user for IPMI device
  users.groups.ipmiusers = {
    name = "ipmiusers";
  };

  services.udev.extraRules = ''
    KERNEL=="ipmi*", MODE="0660", GROUP="ipmiusers"
  '';

  services.emacs.enable = true;
}
