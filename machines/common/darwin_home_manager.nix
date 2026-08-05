{
  config,
  inputs,
  outputs,
  lib,
  ...
}:
let
  cfg = config.neusis.darwin.homeManager;

  extensionFor =
    username:
    cfg.users.${username} or {
      enable = true;
      packageFile = null;
      modules = [ ];
    };

  macUsers = lib.filterAttrs (
    username: user:
    user.home != null && lib.hasPrefix "/Users/" (toString user.home) && (extensionFor username).enable
  ) config.users.users;

  packageModule =
    username: packageFile:
    {
      pkgs,
      inputs,
      outputs,
      ...
    }:
    let
      packageFunction = import packageFile;
      availableArgs = {
        inherit
          pkgs
          inputs
          outputs
          username
          ;
      };
    in
    {
      home.packages = packageFunction (
        lib.intersectAttrs (builtins.functionArgs packageFunction) availableArgs
      );
    };
in
{
  options.neusis.darwin.homeManager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apply the shared Home Manager baseline to configured macOS users.";
    };

    users = lib.mkOption {
      default = { };
      description = "Per-user Home Manager extensions for existing macOS accounts.";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether nix-darwin activates Home Manager for this user.";
              };

              homeDirectory = lib.mkOption {
                type = lib.types.str;
                default = "/Users/${name}";
                description = "Home directory of the existing macOS account.";
              };

              packageFile = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = "Function returning packages; may accept pkgs, inputs, outputs, or username.";
              };

              modules = lib.mkOption {
                type = lib.types.listOf lib.types.deferredModule;
                default = [ ];
                description = "Additional local or external Home Manager modules for this user.";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    # Listing a user here registers metadata for an existing account. Since the
    # user is not added to users.knownUsers, nix-darwin will not create or delete it.
    users.users = lib.mapAttrs (_: user: { home = user.homeDirectory; }) cfg.users;

    home-manager = {
      useGlobalPkgs = lib.mkForce false;
      # Avoid a users.users -> home-manager.users cycle while discovering logins.
      useUserPackages = lib.mkForce false;
      backupFileExtension = "bak";
      # Defaults are per-user module arguments, not specialArgs, so a
      # self-contained external module can override them with its own flake.
      extraSpecialArgs = lib.mkForce { };

      users = lib.mapAttrs (
        username: _:
        let
          userExtension = extensionFor username;
        in
        {
          _module.args = {
            username = lib.mkDefault username;
            inputs = lib.mkDefault inputs;
            outputs = lib.mkDefault outputs;
          };
          imports = [
            ../../homes/common/darwin_home_manager.nix
          ]
          ++ lib.optional (userExtension.packageFile != null) (
            packageModule username userExtension.packageFile
          )
          ++ userExtension.modules;
        }
      ) macUsers;
    };
  };
}
