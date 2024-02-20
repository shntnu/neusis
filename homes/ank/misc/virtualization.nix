
{ pkgs, ... }:
{
  systemd.user.tmpfiles.rules = [
    "f /dev/shm/scream-ivshmem 0660 ${home.username} qemu-libvirtd -"
    "f /dev/shm/looking-glass 0660 ${home.username} qemu-libvirtd -"
  ];

  systemd.user.services.scream-ivshmem = {
    enable = true;
    description = "Scream IVSHMEM";
    serviceConfig = {
      ExecStart = "${pkgs.scream}/bin/scream -m /dev/shm/scream-ivshmem";
      Restart = "always";
    };
    wantedBy = [ "multi-user.target" ];
    requires = [ "pulseaudio.service" ];
  };
}
