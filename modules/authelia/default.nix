{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dedede.services.authelia;
  port = 9091;

  nix-to-config = ./nix-to-config.py;
in
{

  options.dedede.services.authelia = {
    enable = mkEnableOption "authelia authentication server";

    host = mkOption {
      type = types.str;
      default = "auth.dedede.org";
      description = "Host serving authelia";
    };

    cookieDomain = mkOption {
      type = types.str;
      default = "dedede.org";
      description = "Cookie domain for authelia sessions";
    };

    declarativeUsers = {
      enable = lib.mkEnableOption "declarative users";
      users = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = { };
        description = ''
          Authelia users as JSON-compatible attribute sets.
          For any field, use a *File suffix (e.g. passwordFile) to read
          the value from a file at runtime, keeping secrets out of the Nix store.
        '';
        example = lib.literalExpression ''
          {
            pinpox = {
              displayname = "Pablo";
              email = "mail@example.com";
              groups = [ "admins" "users" ];
              passwordFile = "/run/secrets/pinpox-hash";
            };
          }
        '';
      };
    };

    oidcClients = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "OIDC clients for Authelia.";
    };

    oidcAuthorizationPolicies = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Custom authorization policies for OIDC clients.";
    };

    smtp = {
      enable = lib.mkEnableOption "SMTP notifier for Authelia";
      host = lib.mkOption {
        type = lib.types.str;
        description = "SMTP server hostname";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 465;
        description = "SMTP server port";
      };
      username = lib.mkOption {
        type = lib.types.str;
        description = "SMTP username";
      };
      sender = lib.mkOption {
        type = lib.types.str;
        description = "Sender email address";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to file containing SMTP password";
      };
    };

  };

  config = mkIf cfg.enable (
    let
      usersConfigJson = pkgs.writeText "authelia-users-input.json" (
        builtins.toJSON {
          users = lib.mapAttrs (
            _name: user: lib.filterAttrs (_: v: v != null && v != [ ]) user
          ) cfg.declarativeUsers.users;
        }
      );

      oidcConfigJson = pkgs.writeText "authelia-oidc-input.json" (
        builtins.toJSON {
          identity_providers.oidc = {
            clients = cfg.oidcClients;
            cors = {
              endpoints = [ "authorization" "token" "revocation" "introspection" "userinfo" ];
              allowed_origins_from_client_redirect_uris = true;
            };
          } // lib.optionalAttrs (cfg.oidcAuthorizationPolicies != {}) {
            authorization_policies = cfg.oidcAuthorizationPolicies;
          };
        }
      );
    in
    {

      systemd.services.authelia-main = {
        preStart = lib.mkBefore ''
          ${pkgs.python3}/bin/python3 ${nix-to-config} ${usersConfigJson} /run/authelia-main/users.json
          ${lib.optionalString (cfg.oidcClients != []) ''
            ${pkgs.python3}/bin/python3 ${nix-to-config} ${oidcConfigJson} /run/authelia-main/oidc.json
          ''}
        '';
        serviceConfig.RuntimeDirectory = lib.mkDefault "authelia-main";
      };

      services.authelia.instances.main = {
        enable = true;

        secrets = with config.clan.core.vars.generators.authelia.files; {
          jwtSecretFile = jwt-secret.path;
          sessionSecretFile = session-secret.path;
          storageEncryptionKeyFile = storage-encryption-key.path;
        } // lib.optionalAttrs (cfg.oidcClients != []) {
          oidcHmacSecretFile = config.clan.core.vars.generators.authelia.files.oidc-hmac-secret.path;
          oidcIssuerPrivateKeyFile = config.clan.core.vars.generators.authelia.files.oidc-jwks-key.path;
        };

        environmentVariables = lib.mkIf cfg.smtp.enable {
          AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = cfg.smtp.passwordFile;
        };

        settingsFiles = lib.mkIf (cfg.oidcClients != []) [
          "/run/authelia-main/oidc.json"
        ];

        settings = {
          theme = "dark";

          webauthn = {
            enable_passkey_login = true;
            selection_criteria = {
              discoverability = "required";
            };
          };

          server.address = "tcp://127.0.0.1:${toString port}";

          log = {
            level = "info";
            format = "text";
          };

          authentication_backend = {
            file.path = "/run/authelia-main/users.json";
            password_reset.disable = cfg.declarativeUsers.enable;
            password_change.disable = cfg.declarativeUsers.enable;
          };

          access_control = {
            default_policy = "deny";
            rules = [
              {
                domain = "${cfg.host}";
                resources = [ "^/settings.*$" ];
                policy = "two_factor";
              }
              {
                domain = "*.${cfg.cookieDomain}";
                policy = "one_factor";
              }
            ];
          };

          session = {
            name = "authelia_session";
            cookies = [
              {
                domain = cfg.cookieDomain;
                authelia_url = "https://${cfg.host}";
              }
            ];
          };

          storage.local.path = "/var/lib/authelia-main/db.sqlite3";

          notifier = if cfg.smtp.enable then {
            smtp = {
              address = "smtps://${cfg.smtp.host}:${toString cfg.smtp.port}";
              username = cfg.smtp.username;
              sender = cfg.smtp.sender;
            };
          } else {
            filesystem = {
              filename = "/var/lib/authelia-main/notifications.txt";
            };
          };
        };
      };

      clan.core.vars.generators.authelia = {
        files.jwt-secret.owner = "authelia-main";
        files.session-secret.owner = "authelia-main";
        files.storage-encryption-key.owner = "authelia-main";
        files.oidc-hmac-secret.owner = "authelia-main";
        files.oidc-jwks-key.owner = "authelia-main";

        runtimeInputs = with pkgs; [
          coreutils
          openssl
        ];

        script = ''
          mkdir -p $out
          openssl rand -hex 64 > $out/jwt-secret
          openssl rand -hex 64 > $out/session-secret
          openssl rand -hex 64 > $out/storage-encryption-key
          openssl rand -hex 64 > $out/oidc-hmac-secret
          openssl genrsa -out $out/oidc-jwks-key 4096
        '';
      };

      services.caddy = {
        enable = true;
        virtualHosts."${cfg.host}".extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString port}
        '';
      };
    }
  );
}
