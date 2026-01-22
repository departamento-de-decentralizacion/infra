{ ... }:
{
  services.hedgedoc = {
    enable = true;
    settings = {
      domain = "pads.dedede.org";
      host = "127.0.0.1";
      port = 3000;
      protocolUseSSL = true;
      db = {
        dialect = "sqlite";
        storage = "/var/lib/hedgedoc/db.sqlite";
      };
      allowAnonymous = true;
      allowAnonymousEdits = true;
      allowFreeURL = true;
    };
  };

  services.caddy.virtualHosts."https://pads.dedede.org" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3000
    '';
  };
}
