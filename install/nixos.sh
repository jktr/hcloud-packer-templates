#!/bin/bash

# required env:
# - NIX_SIGNING_KEYS
# - NIX_INSTALL_URL
# - NIX_CHANNEL
# - NIX_CONFIG_REPO_URL

set -euo pipefail

# XXX: get nix install working in rescue system
groupadd --force --system nixbld
useradd --system --gid nixbld --groups nixbld nixbld
mkdir -m 0755 /nix && chown root /nix

# obtain nix tools
gpg --batch --receive-keys  ${NIX_SIGNING_KEYS}
curl -so install        "${NIX_INSTALL_URL}"
curl -so install.asc    "${NIX_INSTALL_URL}.asc"
gpg --verify ./install.asc ./install
sh ./install

# make nix tools available to current shell
set +u
. /root/.nix-profile/etc/profile.d/nix.sh
set -u

# prepare nix
nix-channel --add "${NIX_CHANNEL}" nixpkgs
nix-channel --update
nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"

# make configuration.nix
mkdir -p /mnt/etc/nixos/
git clone "${NIX_CONFIG_REPO_URL}" /mnt/etc/nixos/
nixos-generate-config --root /mnt

# actual install
nixos-install --no-root-passwd
