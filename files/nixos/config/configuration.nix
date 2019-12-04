{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hcloud
  ];
}
