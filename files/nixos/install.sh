#!/bin/bash

# required env:
# - NIX_RELEASE
# - NIX_CHANNEL
# - ROOT_SSH_KEY
# - KEYMAP
# - LOCALE
# - TIMEZONE
#
# optional env:
# - EXTRA_PACKAGES

set -euo pipefail

readonly NIX_INSTALL_URL="https://nixos.org/releases/nix/nix-${NIX_RELEASE}/install"
readonly NIX_CHANNEL_URL="https://nixos.org/channels/nixos-${NIX_CHANNEL}"

# XXX: get nix install working in rescue system
groupadd --force --system nixbld
useradd --system --gid nixbld --groups nixbld nixbld
mkdir -m 0755 /nix && chown root /nix

# obtain nix tools
curl --fail -o install     "${NIX_INSTALL_URL}"
curl --fail -o install.asc "${NIX_INSTALL_URL}.asc"
gpg --verify ./install.asc ./install
sh ./install

# make nix tools available to current shell
set +u
. /root/.nix-profile/etc/profile.d/nix.sh
set -u

# prepare nix
nix-channel --add "${NIX_CHANNEL_URL}" nixpkgs
nix-channel --update
nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"

# make configuration.nix
mkdir -p /mnt/etc/nixos/
cat > /mnt/etc/nixos/configuration.nix <<EOF
{ config, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/profiles/headless.nix>
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    ${EXTRA_PACKAGES}
  ];

  boot.loader.grub.device = "/dev/sda";
  system.autoUpgrade.enable = true;

  i18n = {
    consoleKeyMap = "${KEYMAP}";
    defaultLocale = "${LOCALE}";
  };
  time.timeZone = "${TIMEZONE}";

  services.openssh = {
    enable = true;
    challengeResponseAuthentication = false;
    passwordAuthentication = false;
  };

  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keys = [ "$ROOT_SSH_KEY" ];
  };
}
EOF
nixos-generate-config --root /mnt

# actual install
nixos-install --no-root-passwd
