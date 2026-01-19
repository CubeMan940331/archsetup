#!/bin/bash
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}" || exit 1

NAME=$(basename "${SCRIPT_PATH}" | sed -e 's/^[0-9]*-//g')
echo "start executing ${NAME} script"

# script =======================
# copy file
cp files/sshd.local /etc/fail2ban/jail.d/ &&

# enable service
systemctl enable sshd &&
systemctl enable fail2ban
