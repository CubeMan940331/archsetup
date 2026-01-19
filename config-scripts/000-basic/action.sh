#!/bin/bash
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}" || exit 1

NAME=$(basename "${SCRIPT_PATH}" | sed -e 's/^[0-9]*-//g')
echo "start executing ${NAME} script"

# script =======================
source "files/basic.conf"

# TimeZone
ln -sf /usr/share/zoneinfo/"${time_zone}" /etc/localtime
hwclock --systohc

# locale
for item in "${locale_list[@]}"; do
    sed -e 's/^#'"${item}"'/'"${item}"'/' \
        < /etc/locale.gen \
        > /tmp/locale.gen &&
    mv /tmp/locale.gen /etc/locale.gen
done
locale-gen

echo "LANG=${default_locale}" > /etc/locale.conf

# hostname
echo "${host_name}" > /etc/hostname

# root passwd
echo "${root_passwd}" | passwd -s root

# add user
useradd -mG wheel "${user_name}"
echo "${user_passwd}" | passwd -s "${user_name}"

systemctl enable NetworkManager

mkdir -p /etc/sudoers.d/ &&
cp files/sudo-settings /etc/sudoers.d/
