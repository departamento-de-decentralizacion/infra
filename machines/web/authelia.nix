{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Define all users: username -> groups
  users = {
    pinpox = [
      "admins"
      "users"
    ];
    lassulus = [
      "admins"
      "users"
    ];
    k4os = [ "users" ];
    freerk = [ "users" ];
    cheesus = [ "users" ];
  };

  mkUserPasswordGenerator = username: {
    files.password = { };
    files.password-hash.owner = "authelia-main";
    runtimeInputs = with pkgs; [
      coreutils
      authelia
      xkcdpass
      gnused
    ];
    script = ''
      mkdir -p $out
      xkcdpass -n 7 -d- > $out/password
      authelia crypto hash generate argon2 --password "$(cat $out/password)" | sed 's/^Digest: //' > $out/password-hash
    '';
  };

  mkUser = username: groups: {
    displayname = username;
    email = "${username}@dedede.org";
    inherit groups;
    passwordFile =
      config.clan.core.vars.generators."authelia-user-${username}".files.password-hash.path;
  };
in
{
  imports = [ ../../modules/authelia ];

  clan.core.vars.generators = lib.mapAttrs' (
    username: _: lib.nameValuePair "authelia-user-${username}" (mkUserPasswordGenerator username)
  ) users;

  dedede.services.authelia = {
    enable = true;
    host = "auth.dedede.org";
    cookieDomain = "dedede.org";

    declarativeUsers = {
      enable = true;
      users = lib.mapAttrs mkUser users;
    };

    oidcAuthorizationPolicies = {
      hedgedoc-users = {
        default_policy = "deny";
        rules = [
          {
            policy = "one_factor";
            subject = "group:users";
          }
        ];
      };
    };

    oidcClients = [
      {
        client_id = "hedgedoc";
        client_secret_file = config.clan.core.vars.generators."hedgedoc-oidc".files.client_secret.path;
        redirect_uris = [ "https://pads.dedede.org/auth/oauth2/callback" ];
        scopes = [
          "openid"
          "email"
          "profile"
          "groups"
        ];
        authorization_policy = "hedgedoc-users";
      }
    ];
  };
}
