{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hcloud/default.nix
    ./hcloud/user/configuration.nix
  ];
}
