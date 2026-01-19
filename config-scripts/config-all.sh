#!/bin/bash
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$(basename "${BASH_SOURCE[0]}")"
cd $SCRIPT_PATH

echo "install pkgs"
pacman -S --noconfirm --needed $(cat ./*/pkg.txt | grep -v '^#')
echo "" > /var/archsetup_install.log
while read -r item; do
    item_name=$(basename "$item" | sed -e 's/^[0-9]*-//g')
    if [ ! -e "$item/action.sh" ]; then
        continue
    fi
    echo "$item_name" | tee -a /var/archsetup_install.log
    if ! (
        "$item/action.sh" 2>&1 | tee -a /var/archsetup_install.log
    ); then
        echo "script in $item_name failed"
        echo "check /var/archsetup_install.log"
        exit 1
    fi
done < "list.txt"
