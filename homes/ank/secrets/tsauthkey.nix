{ config, ... }:
{
  config.age.secrets.tsauthkey.file = ../../secrets/tsauthkey.age;
}
