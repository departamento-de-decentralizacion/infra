{
  # Ensure this is unique among all clans you want to use.
  meta.name = "departamento-de-decentralizacion";
  meta.domain = "ddd";

  inventory.machines.web = { };
  inventory.machines.uno.tags = [ "workstation" ];

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

    # Workstations (laptops)
    kde.roles.default.tags = [ "workstation" ];

    users-hacker = {
      module.name = "users";
      roles.default.tags.workstation = { };
      roles.default.settings = {
        user = "hacker";
        prompt = true;
      };
    };

    wifi = {
      roles.default = {
        tags = [ "workstation" ];
        settings.networks.casa_ciencia = { };
      };
    };
  };

  secrets.age.plugins = [
    "github:pinpox/age-plugin-picohsm#default"
  ];

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
