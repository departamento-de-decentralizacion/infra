{ config, pkgs, ... }:
{
  clan.core.vars.generators."hedgedoc-oidc" = {
    files.client_secret.owner = "authelia-main";
    files.client_secret_env.owner = "hedgedoc";
    runtimeInputs = with pkgs; [
      coreutils
      openssl
    ];
    script = ''
      mkdir -p $out
      openssl rand -hex 32 > $out/client_secret
      echo "CMD_OAUTH2_CLIENT_SECRET=$(cat $out/client_secret)" > $out/client_secret_env
    '';
  };

  services.hedgedoc = {
    enable = true;
    environmentFile = config.clan.core.vars.generators."hedgedoc-oidc".files.client_secret_env.path;
    settings = {
      domain = "pads.dedede.org";
      host = "127.0.0.1";
      port = 3000;
      protocolUseSSL = true;
      db = {
        dialect = "sqlite";
        storage = "/var/lib/hedgedoc/db.sqlite";
      };

      # Keep anonymous access
      allowAnonymous = true;
      allowAnonymousEdits = true;
      allowFreeURL = true;

      # OAuth2 with Authelia
      oauth2 = {
        providerName = "Authelia";
        clientID = "hedgedoc";
        # clientSecret comes from environmentFile as CMD_OAUTH2_CLIENT_SECRET
        scope = "openid email profile";
        userProfileURL = "https://auth.dedede.org/api/oidc/userinfo";
        tokenURL = "https://auth.dedede.org/api/oidc/token";
        authorizationURL = "https://auth.dedede.org/api/oidc/authorization";
        userProfileUsernameAttr = "preferred_username";
        userProfileDisplayNameAttr = "name";
        userProfileEmailAttr = "email";
      };
    };
  };

  services.caddy.virtualHosts."https://pads.dedede.org" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3000
    '';
  };
}
