{ ... }:
{
  # This setups a SSH server. Very important if you're setting up a headless system.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      # Password authentication is narrowed to wheel members below.
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      StreamLocalBindUnlink = "yes";
      # Allow forwarding ports to everywhere
      GatewayPorts = "clientspecified";
      X11Forwarding = true;
    };
    extraConfig = ''
      # Admins are wheel members. Everyone else must use an SSH key.
      Match Group *,!wheel
          PasswordAuthentication no
          KbdInteractiveAuthentication no
    '';
  };

  # Fleet ssh_config: forward the user's agent to any SSH destination.
  # Lets users chain into other hosts (oppy -> spirit -> karkinos, and
  # anything reachable from a fleet box) without having to copy private
  # keys onto the origin machine. Trust boundary: any SSH server they
  # connect to from a fleet host can use their forwarded agent while the
  # connection is open.
  programs.ssh.extraConfig = ''
    Host *
        ForwardAgent yes
  '';
}
