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

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILJlhT8EjImUosmzlN8SL9STN351kICSZ3YVOY6SiYtc freerk"
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

  vars.settings.secretStore = "age";
  vars.settings.recipients.default = [
    # pinpox
    "age1picohsm1qjpqjd9pnlh8zem6wwz62ml9z995fsdz9e23dumamjj0nl4cq0m5dx5v5mm5njelm3hmv4w3mfs5mzvks3xtu6k723jr0am49hrk9mduxvxpps"
    # lassulus
    "age1fa8p9xf28xx78yk2zqlkxgzy8kraraps9w9ky73s59dfedqmcshq8rg6le"
  ];

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
