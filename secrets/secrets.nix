let
  ank = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINp8DUNWx6rrzqYU8ejdQxxbXpS/rmp+G/3HXDozwNu6 ank@leoank.me";
  users = [ ank ];

  karkinos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFH40XzfXPtcTwJ8FHxHXCaEteylFOwtuw5TaY5CZ5NS ank@leoank.me";
  oppy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINCW3CZ4r7VhI7+4rC+oOE4n3AMXEy3F2vm8jjHeTClR";
  systems = [
    karkinos
    oppy
  ];
in
{
  "ank_userpass.age".publicKeys = [ ank ];
  "tsauthkey.age".publicKeys = users ++ systems;

  # Oppy
  "oppy_ssh_host_key.age" = {
    publicKeys = [
      ank
      oppy
    ];
  };
}
