#!/bin/bash
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$(basename "${BASH_SOURCE[0]}")"
cd $SCRIPT_PATH

echo "install pkgs"
pacman -S --noconfirm --needed $(cat ./*/pkg.txt | grep -v '^#')
for item in ./*; do
    item_name=$(basename "$item" | sed -e 's/^[0-9]*-//g')
    if [ ! -e "$item/action.sh" ]; then
        continue
    fi
    if ! (
        "$item/action.sh" 2>&1 | tee "$item/log.txt"
    ); then
        echo "script in $item_name failed"
        echo "check $item/log.txt"
        exit 1
    fi
done
