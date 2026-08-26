{
  pkgs,
  ...
}:
{

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.autoSuspend = false;
  services.desktopManager.gnome.enable = true;

  # Prevent GNOME from attempting idle suspend on a shared server
  # (nosleep.nix masks the systemd targets, but gsd-power still sends a
  # misleading "The system will suspend now!" broadcast before logind refuses)
  #
  # nixos-gsettings-overrides only compiles schemas from the packages listed in
  # extraGSettingsOverridePackages (plus gsettings-desktop-schemas and
  # gnome-shell). Without gnome-settings-daemon here, glib-compile-schemas has
  # no org.gnome.settings-daemon.plugins.power schema to apply the override to
  # and drops it silently, leaving sleep-inactive-ac-type at 'suspend'.
  services.desktopManager.gnome.extraGSettingsOverridePackages = [ pkgs.gnome-settings-daemon ];
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.settings-daemon.plugins.power]
    sleep-inactive-ac-type='nothing'
    sleep-inactive-battery-type='nothing'
  '';

  # ollama needs imaging group to traverse /work (0750 root:imaging)
  users.users.ollama = {
    isSystemUser = true;
    group = "ollama";
    extraGroups = [ "imaging" ];
  };
  users.groups.ollama = {};

  # enable ollama
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama;
    acceleration = "cuda";
    models = "/work/tools/ollama";
    host = "0.0.0.0";
    port = 11434;
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "262144";
    };
  };

  nixpkgs.config.sunshine.cudaSupport = true;

  # Karkinos-specific packages (base packages in common/system.nix)
  environment.systemPackages = with pkgs; [
    unstable.ollama
    gnomeExtensions.forge
    gnomeExtensions.blur-my-shell
    gnomeExtensions.burn-my-windows
    gnomeExtensions.appindicator
    gnomeExtensions.unite
  ];

}
