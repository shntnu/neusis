let
  ank = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINp8DUNWx6rrzqYU8ejdQxxbXpS/rmp+G/3HXDozwNu6 ank@leoank.me";
  karkinos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINp8DUNWx6rrzqYU8ejdQxxbXpS/rmp+G/3HXDozwNu6 ank@leoank.me";
in
{
  "ank_userpass.age".publicKeys = [ ank ];
  "tsauthkey.age".publicKeys = [ ank karkinos ];
}
