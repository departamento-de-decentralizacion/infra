{ inputs, ... }:
{
  services.caddy = {
    enable = true;
    virtualHosts."https://dedede.org" = {
      extraConfig = ''
        root * ${inputs.dedede-web}
        file_server
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
