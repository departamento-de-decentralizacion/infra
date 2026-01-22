{
  # Ensure this is unique among all clans you want to use.
  meta.name = "departamento-de-decentralizacion";
  meta.domain = "ddd";

  inventory.machines.web = { };

  inventory.instances = {

    tor.roles.server.tags.nixos = { };
    yggdrasil.roles.default.tags.all = { };
    sshd.roles.server.tags.all = { };

    internet = {
      roles.default.machines.web = {
        settings.host = "5.161.64.210";
      };
    };

    users-root = {
      module.name = "users";
      roles.default.tags.all = { };
      roles.default.settings = {
        user = "root";
        prompt = false;
      };
    };
  };

  machines = {
    web =
      {
        # config,
        ...
      }:
      {

        services.openssh.enable = true;

        users.users.root.openssh.authorizedKeys.keys = [

          # pinpox
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCdOfrnazSXp7ZmHcePXSd4leP3Qafr4fmDr3w+AxwRChSn1zzLPjV8CvD/PdMU7jQA0HS/1ItREurmZCKS/ZnQ= ssh-key"
        ];


      };
  };
}
