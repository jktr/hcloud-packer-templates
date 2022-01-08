#!/bin/bash

# required env:
# - NIX_RELEASE
# - NIX_CHANNEL
# - ROOT_SSH_KEY
# - KEYMAP
# - LOCALE
# - TIMEZONE
# - EXTRA_PACKAGES

set -euo pipefail

readonly NIX_INSTALL_URL="https://releases.nixos.org/nix/nix-${NIX_RELEASE}/install"
readonly NIX_CHANNEL_URL="https://channels.nixos.org/nixos-${NIX_CHANNEL}"

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

# XXX: template the nix config previously injected by packer
for i in NIX_CHANNEL KEYMAP LOCALE TIMEZONE ROOT_SSH_KEY EXTRA_PACKAGES; do
  sed -i "s|{{ $i }}|${!i}|"  /mnt/etc/nixos/hcloud/default.nix
done
nixos-generate-config --root /mnt

# actual install
nixos-install --no-root-passwd
