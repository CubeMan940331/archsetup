#!/bin/bash
set -eo pipefail
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}" || exit 1
# script =======================
if [[ ! -e "/etc/sddm.conf.d/" ]]; then
    mkdir -p /etc/sddm.conf.d/
fi

# copy file
cp files/theme.conf /etc/sddm.conf.d/ &&

# enable service
systemctl enable sddm
