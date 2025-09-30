{ config, pkgs, ... }:

{
  # Enable JupyterHub multi-user server
  services.jupyterhub = {
    enable = true;

    # Network configuration
    host = "0.0.0.0";  # Listen on all interfaces
    port = 8000;

    # Authentication - uses PAM by default for system users
    authentication = "jupyterhub.auth.PAMAuthenticator";

    # State directory for JupyterHub database and config
    # NixOS will create this as /var/lib/jupyterhub
    stateDirectory = "jupyterhub";

    # Minimal base environment - users manage packages via uv/pixi
    # Only includes JupyterLab itself and kernel support
    jupyterlabEnv = pkgs.python3.withPackages (ps: with ps; [
      jupyterhub
      jupyterlab
      notebook
      ipykernel
      ipywidgets
      # Required for users to register custom kernels
      jupyter-client
      # No data science packages - users install via uv/pixi
    ]);

    # Configure kernels
    kernels = {
      # Minimal base Python kernel - users create their own via uv/pixi
      python3 = let
        env = (pkgs.python3.withPackages (ps: with ps; [
          ipykernel
        ]));
      in {
        displayName = "Python 3";
        argv = [
          "${env.interpreter}"
          "-m"
          "ipykernel_launcher"
          "-f"
          "{connection_file}"
        ];
        language = "python";
        env = { };
      };
    };

    # Additional configuration
    extraConfig = ''
      # Admin users who can access other users' servers
      c.Authenticator.admin_users = {'shsingh'}

      # Allow all system users to authenticate (JupyterHub 5.0+ requires explicit allow_all)
      c.Authenticator.allow_all = True

      # Spawner configuration
      c.SystemdSpawner.default_shell = '/run/current-system/sw/bin/bash'
      c.SystemdSpawner.mem_limit = '4G'
      c.SystemdSpawner.cpu_limit = 2.0

      # User workspace directory (aligned with data storage policy)
      # Users can access their entire /work/users/{username}/ directory
      c.SystemdSpawner.user_workingdir = '/work/users/{USERNAME}'
      c.SystemdSpawner.notebook_dir = '~/'
      
      # Add user's local bin to PATH for uv/pixi installations
      c.SystemdSpawner.extra_paths = ['/work/users/{USERNAME}/.local/bin']

      # Automatically create user directory and set environment if needed
      import os
      def pre_spawn_hook(spawner):
          username = spawner.user.name
          user_dir = f'/work/users/{username}'

          # Create directory if it doesn't exist
          os.makedirs(user_dir, mode=0o755, exist_ok=True)
          
          # Set user-specific environment variables
          spawner.environment.update({
              'UV_CACHE_DIR': f'/work/users/{username}/.cache/uv',
              'PIXI_HOME': f'/work/users/{username}/.pixi',
          })

          # Set ownership (requires running as root)
          import pwd
          try:
              pw = pwd.getpwnam(username)
              os.chown(user_dir, pw.pw_uid, pw.pw_gid)
          except KeyError:
              pass  # User doesn't exist yet

      c.Spawner.pre_spawn_hook = pre_spawn_hook

      # Cookie secret for security
      c.JupyterHub.cookie_secret_file = '/var/lib/jupyterhub/jupyterhub_cookie_secret'

      # Database location
      c.JupyterHub.db_url = 'sqlite:////var/lib/jupyterhub/jupyterhub.sqlite'

      # Cleanup settings
      c.JupyterHub.cleanup_servers = True
      c.JupyterHub.cleanup_proxy = True

      # Activity tracking
      c.JupyterHub.last_activity_interval = 300
      c.JupyterHub.shutdown_on_logout = True

      # Security: Use IPC transport for kernel communication (Unix socket permissions)
      # Prevents eavesdropping between users on shared system
      c.KernelManager.transport = 'ipc'

      # Security: Subdomain isolation (requires wildcard DNS)
      # IMPORTANT: Configure DNS with *.jupyter.oppy -> oppy
      # c.JupyterHub.subdomain_host = 'https://jupyter.oppy'

      # Services API tokens (if needed for external services)
      # c.JupyterHub.services = []
    '';
  };

  # Create base directory for JupyterHub users (aligned with data storage policy)
  systemd.tmpfiles.rules = [
    "d /work/users 0755 root root -"
  ];

  # Install uv and pixi globally for all JupyterHub users
  # uv: 10x faster than pip, manages Python versions and virtual environments
  # pixi: Handles both conda and PyPI packages with lockfile support
  environment.systemPackages = with pkgs; [
    uv        # Fast Python package manager (pip/venv replacement)
    pixi      # Package manager for conda/PyPI packages
  ];

  # Configure PAM for JupyterHub authentication
  security.pam.services.jupyterhub = {
    unixAuth = true;
  };

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8000 ];

  # Nginx proxy removed - access JupyterHub directly at http://oppy:8000
}