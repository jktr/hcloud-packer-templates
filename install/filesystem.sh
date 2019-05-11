#!/bin/bash

set -euo pipefail

# required env
# - LABEL filestystem label

# partitions
dd if=/dev/zero of=/dev/sda bs=1MiB count=1 status=none
xargs -L1 parted --script /dev/sda -- <<EOF
mklabel msdos
mkpart primary btrfs 1MiB -2GiB
mkpart primary linux-swap -2GiB 100%
set 1 boot on
EOF

# filesystems
mkfs.btrfs --force --label "${LABEL}" /dev/sda1
mount -o compress=lzo,commit=90,autodefrag /dev/sda1 /mnt
mkswap -L swap /dev/sda2
swapon /dev/sda2
