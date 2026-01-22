{ ... }:
{
  services.alps = {
    enable = true;
    theme = "alps";
    port = 1323;
    imaps = {
      host = "mail.privateemail.com";
      port = 993;
    };
    smtps = {
      host = "mail.privateemail.com";
      port = 465;
    };
  };

  services.caddy.virtualHosts."https://webmail.dedede.org" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:1323
    '';
  };
}
