{ config, pkgs, ... }:
let
  mkUserPasswordGenerator = username: {
    files.password = { };
    files.password-hash.owner = "authelia-main";
    runtimeInputs = with pkgs; [ coreutils authelia xkcdpass gnused ];
    script = ''
      mkdir -p $out
      xkcdpass -n 7 -d- > $out/password
      authelia crypto hash generate argon2 --password "$(cat $out/password)" | sed 's/^Digest: //' > $out/password-hash
    '';
  };
in
{
  imports = [ ../../modules/authelia ];

  clan.core.vars.generators."authelia-user-pinpox" = mkUserPasswordGenerator "pinpox";
  clan.core.vars.generators."authelia-user-lassulus" = mkUserPasswordGenerator "lassulus";
  clan.core.vars.generators."authelia-user-k4os" = mkUserPasswordGenerator "k4os";

  # OIDC client secret for HedgeDoc
  clan.core.vars.generators."hedgedoc-oidc" = {
    files.client_secret.owner = "authelia-main";
    files.client_secret_env.owner = "hedgedoc";
    runtimeInputs = with pkgs; [ coreutils openssl ];
    script = ''
      mkdir -p $out
      openssl rand -hex 32 > $out/client_secret
      echo "CMD_OAUTH2_CLIENT_SECRET=$(cat $out/client_secret)" > $out/client_secret_env
    '';
  };

  dedede.services.authelia = {
    enable = true;
    host = "auth.dedede.org";
    cookieDomain = "dedede.org";

    declarativeUsers = {
      enable = true;
      users = {
        pinpox = {
          displayname = "pinpox";
          email = "pinpox@dedede.org";
          groups = [ "admins" "users" ];
          passwordFile = config.clan.core.vars.generators."authelia-user-pinpox".files.password-hash.path;
        };
        lassulus = {
          displayname = "lassulus";
          email = "lassulus@dedede.org";
          groups = [ "admins" "users" ];
          passwordFile = config.clan.core.vars.generators."authelia-user-lassulus".files.password-hash.path;
        };
        k4os = {
          displayname = "k4os";
          email = "k4os@dedede.org";
          groups = [ "users" ];
          passwordFile = config.clan.core.vars.generators."authelia-user-k4os".files.password-hash.path;
        };
      };
    };

    oidcAuthorizationPolicies = {
      hedgedoc-users = {
        default_policy = "deny";
        rules = [
          { policy = "one_factor"; subject = "group:users"; }
        ];
      };
    };

    oidcClients = [
      {
        client_id = "hedgedoc";
        client_secret_file = config.clan.core.vars.generators."hedgedoc-oidc".files.client_secret.path;
        redirect_uris = [ "https://pads.dedede.org/auth/oauth2/callback" ];
        scopes = [ "openid" "email" "profile" "groups" ];
        authorization_policy = "hedgedoc-users";
      }
    ];
  };
}
