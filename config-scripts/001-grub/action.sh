#!/bin/bash
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}" || exit 1

NAME=$(basename "${SCRIPT_PATH}" | sed -e 's/^[0-9]*-//g')
echo "start executing ${NAME} script"

# script =======================
grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot \
    --bootloader-id=grub &&
grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot \
    --bootloader-id=grub \
    --removable &&

mkdir -p /etc/default/grub.d &&
cp files/os-prob.cfg /etc/default/grub.d &&
grub-mkconfig -o /boot/grub/grub.cfg
