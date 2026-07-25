#!/bin/bash
set -eo pipefail
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}"
NAME=$(basename "${SCRIPT_PATH}" | sed -e 's/^[0-9]*-//g')
# script =======================
systemctl enable NetworkManager
systemctl enable paccache.timer
systemctl enable systemd-timesyncd

mkdir -p /etc/systemd/journald.conf.d/
cp files/size-limit.conf /etc/systemd/journald.conf.d/
