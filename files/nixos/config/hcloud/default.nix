{ lib, config, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/profiles/headless.nix>
    ./hcloud-metadata.nix
    ./user/configuration.nix
  ];

  system.stateVersion = "{{ NIX_CHANNEL }}";

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  environment.systemPackages = with pkgs; [
    (python3.withPackages (f: [f.pyyaml]))
    {{ EXTRA_PACKAGES }}
  ];

  i18n.defaultLocale = lib.mkDefault "{{ LOCALE }}";
  console.keyMap = lib.mkDefault "{{ KEYMAP }}";
  time.timeZone = lib.mkDefault "{{ TIMEZONE }}";

  boot = {
    tmpOnTmpfs = lib.mkDefault true;
    loader.grub.device = lib.mkDefault "/dev/sda";
  };

  system.autoUpgrade.enable = lib.mkDefault true;
  nix = {
    autoOptimiseStore = lib.mkDefault true;
    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "daily";
      options = lib.mkDefault "--delete-older-than 7d";
    };
  };

  services.openssh.enable = lib.mkDefault true;
  users.users.root.openssh.authorizedKeys.keys = lib.mkDefault [
    "{{ ROOT_SSH_KEY }}"
  ];

  services.resolved.enable = lib.mkDefault true;

  networking.dhcpcd.enable = lib.mkDefault false;
  systemd.network = {
    enable = lib.mkDefault true;
    networks.default = lib.mkDefault {
      matchConfig.Match = "en*";
      networkConfig.DHCP = "yes";
    };
  };
}
