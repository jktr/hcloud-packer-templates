#!/bin/bash

# required env:
# - ARCH_SIGNING_KEYS
# - ARCH_MIRROR
# - ARCH_IMAGE
# - ROOT_SSH_KEY
# - KEYMAP
# - LOCALE
# - TIMEZONE

set -euo pipefail

# obtain arch tools
gpg --batch --receive-keys ${ARCH_SIGNING_KEYS}
curl --fail -o "${ARCH_IMAGE}"     "${ARCH_MIRROR}/iso/latest/${ARCH_IMAGE}"
curl --fail -o "${ARCH_IMAGE}.sig" "${ARCH_MIRROR}/iso/latest/${ARCH_IMAGE}.sig"
gpg --verify "./${ARCH_IMAGE}.sig" "./${ARCH_IMAGE}"
tar xzf "./${ARCH_IMAGE}"
rm "./${ARCH_IMAGE}" # save memory

# prepare mounts
readonly iso='/root/root.x86_64'
mount --bind "$iso" "$iso" # XXX arch-chroot needs / to be a mountpoint
mount --bind /mnt "$iso/mnt"

# install base
"$iso/bin/arch-chroot" "$iso" <<EOF
set -euo pipefail

# pacstrap
echo 'Server = ${ARCH_MIRROR}/\$repo/os/\$arch' > /etc/pacman.d/mirrorlist
pacman-key --init
pacman-key --populate archlinux
pacstrap -d /mnt base grub btrfs-progs openssh python rxvt-unicode-terminfo alacritty-terminfo

# fstab
genfstab -U /mnt > /mnt/etc/fstab
echo 'proc /proc proc defaults,hidepid=2 0 0' >> /mnt/etc/fstab

EOF

# set ssh key
install -o root -g root -D -m 640 \
        <(echo "${ROOT_SSH_KEY}") \
        /mnt/root/.ssh/authorized_keys

# sync dns settings
cp /etc/resolv.conf /mnt/etc/

# configure base
"$iso/bin/arch-chroot" /mnt <<EOF
set -euo pipefail

# time
systemctl enable systemd-timesyncd
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# locale
echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
echo '${LOCALE} UTF-8' > /etc/locale.gen
echo 'LANG=${LOCALE}' > /etc/locale.conf
locale-gen

# network
systemctl enable systemd-networkd sshd
cat > /etc/systemd/network/default.network <<EOF2
[Match]
Name=en*
[Network]
DHCP=yes
EOF2

# grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg /dev/sda

# misc
systemctl set-default multi-user.target
usermod -L root
echo 'archlinux' > /etc/hostname

EOF
