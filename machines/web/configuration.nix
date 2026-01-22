{
  imports = [
    ./website.nix
    ./hedgedoc.nix
  ];

  networking.interfaces.ens3 = {
    ipv6.addresses = [
      {
        address = "2a01:4ff:f0:f32d::1";
        prefixLength = 64;
      }
    ];
  };

}
