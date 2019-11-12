#!/bin/bash

set -euo pipefail

# required env
# - LABEL filestystem label

# partitions
dd if=/dev/zero of=/dev/sda bs=1MiB count=1 status=none
xargs -L1 parted --script /dev/sda -- <<EOF
mklabel msdos
mkpart primary linux-swap 1MiB 2GiB
mkpart primary btrfs 2GiB 100%
set 1 boot on
EOF

# filesystems
mkswap -L swap /dev/sda1
swapon /dev/sda1
mkfs.btrfs --force --label "${LABEL}" /dev/sda2
mount -o compress=lzo,commit=90,autodefrag /dev/sda2 /mnt
