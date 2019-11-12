{ config, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/profiles/headless.nix>
  ];

  system.stateVersion = "{{ NIX_CHANNEL }}";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  environment.systemPackages = with pkgs; [
    {{ EXTRA_PACKAGES }}
  ];

  i18n = {
    consoleKeyMap = "{{ KEYMAP }}";
    defaultLocale = "{{ LOCALE }}";
  };
  time.timeZone = "{{ TIMEZONE }}";

  boot = {
    tmpOnTmpfs = true;
    loader.grub.device = "/dev/sda";
  };

  system.autoUpgrade.enable = true;
  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  services.openssh.enable = true;
}
