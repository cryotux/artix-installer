#!/bin/sh -e
#
# A simple installer for Artix Linux
#
# Copyright (c) 2022 Maxwell Anderson
#
# This file is part of artix-installer.
#
# artix-installer is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# artix-installer is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with artix-installer. If not, see <https://www.gnu.org/licenses/>.

# Timezone
ln -sf "/usr/share/zoneinfo/$REGION_CITY" /etc/localtime
hwclock --systohc

# Localization
if ! grep -q "^#*$LANGCODE\.UTF-8 UTF-8" /etc/locale.gen; then
	printf "%s.UTF-8 UTF-8\n" "$LANGCODE" >>/etc/locale.gen
fi

locale-gen

printf "LANG=%s.UTF-8\n" "$LANGCODE" >/etc/locale.conf
printf "KEYMAP=%s\n" "$MY_KEYMAP" >/etc/vconsole.conf

# Hostname
printf '%s\n' "$MY_HOSTNAME" >/etc/hostname

if [ "$MY_INIT" = "openrc" ]; then
	printf 'hostname="%s"\n' "$MY_HOSTNAME" >/etc/conf.d/hostname
fi

printf "\n127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t%s.localdomain\t%s\n" \
	"$MY_HOSTNAME" "$MY_HOSTNAME" >/etc/hosts

# Configure GRUB
root_uuid=$(blkid "$PART2" -o value -s UUID)

if [ "$ENCRYPTED" = "y" ]; then
	my_params="cryptdevice=UUID=$root_uuid:root root=/dev/mapper/root"
else
	my_params=""
fi

# Btrfs root subvolume
if [ "$MY_FS" = "btrfs" ]; then
	if [ -n "$my_params" ]; then
		my_params="$my_params rootflags=subvol=root"
	else
		my_params="rootflags=subvol=root"
	fi
fi

sed -i \
	"s|^GRUB_CMDLINE_LINUX_DEFAULT.*$|GRUB_CMDLINE_LINUX_DEFAULT=\"$my_params\"|g" \
	/etc/default/grub

# Install UEFI GRUB
grub-install \
	--target=x86_64-efi \
	--efi-directory=/boot \
	--recheck

grub-install \
	--target=x86_64-efi \
	--efi-directory=/boot \
	--removable \
	--recheck

grub-mkconfig -o /boot/grub/grub.cfg

# Root password
printf 'root:%s\n' "$ROOT_PASSWORD" | chpasswd

# Enable wheel sudo permissions
sed -i '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers

# Configure networking and swap
if [ "$MY_INIT" = "openrc" ]; then
	sed -i '/rc_need="localmount"/s/^#//g' /etc/conf.d/swap
	rc-update add connmand default

elif [ "$MY_INIT" = "dinit" ]; then
	ln -sf /etc/dinit.d/connmand /etc/dinit.d/boot.d/
fi

# Configure mkinitcpio
if [ "$MY_FS" = "btrfs" ]; then
	sed -i \
		's|^BINARIES=.*$|BINARIES=(/usr/bin/btrfs)|' \
		/etc/mkinitcpio.conf
fi

if [ "$ENCRYPTED" = "y" ]; then
	sed -i \
		's|^HOOKS=.*$|HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)|' \
		/etc/mkinitcpio.conf
else
	sed -i \
		's|^HOOKS=.*$|HOOKS=(base udev autodetect keyboard keymap modconf block filesystems fsck)|' \
		/etc/mkinitcpio.conf
fi

# Regenerate initramfs
mkinitcpio -P
