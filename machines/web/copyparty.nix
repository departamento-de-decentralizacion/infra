{ pkgs, ... }:
let
  configFile = pkgs.writeText "copyparty.conf" ''
    [global]
      i: 127.0.0.1
      p: 3923

      # Accept user identity from reverse proxy headers (set by Authelia)
      idp-h-usr: Remote-User
      idp-h-grp: Remote-Groups

      # Only accept IdP headers from localhost (reverse proxy)
      xff-src: 127.0.0.0/8

    [/]
      /var/lib/copyparty
      accs:
        rwmd: @admins
        rw: @users
  '';
in
{
  systemd.services.copyparty = {
    description = "Copyparty file server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.copyparty}/bin/copyparty -c ${configFile}";
      StateDirectory = "copyparty";
      DynamicUser = true;
      Restart = "on-failure";
    };
  };

  services.caddy.virtualHosts."https://copy.dedede.org" = {
    extraConfig = ''
      forward_auth http://127.0.0.1:9091 {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
      }
      reverse_proxy 127.0.0.1:3923
    '';
  };
}
