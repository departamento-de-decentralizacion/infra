{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "America/Bogota";
  programs.firefox = {
    enable = true;
    preferences = {
      "browser.startup.homepage" = "https://dedede.org";
    };
    policies.ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };

  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.htop.enable = true;
  programs.steam.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  hardware.bluetooth.enable = true;
}
