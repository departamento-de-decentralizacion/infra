{
  self,
  ...
}:
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
    sshd.roles.server.extraModules = [
      {

        services.openssh.enable = true;
        users.users.root.openssh.authorizedKeys.keyFiles = with self.inputs; [
          pinpox-keys
          lassulus-keys
        ];
      }
    ];

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
    kde.roles.default.extraModules = [ ./modules/workstation.nix ];

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

      };
  };
}
