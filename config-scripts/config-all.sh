#!/bin/bash
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}" || exit 1

echo "install pkgs"
pkg_files=""
while read -r item; do
    if [ -e "${item}/pkg.txt" ]; then
        pkg_files="${pkg_files} ${item}/pkg.txt"
    fi
done < "list.txt"
cat $pkg_files | grep -v '^#'  | pacman -S - --noconfirm --needed

echo "" > /var/archsetup_install.log
while read -r item; do
    item_name=$(basename "$item" | sed -e 's/^[0-9]*-//g')
    if [ ! -e "$item/action.sh" ]; then
        continue
    fi
    echo "${item_name}" | tee -a /var/archsetup_install.log
    chmod +x "${item}/action.sh"
    if ! (
        "${item}/action.sh" 2>&1 | tee -a /var/archsetup_install.log
    ); then
        echo "script in $item_name failed"
        echo "check /var/archsetup_install.log"
        exit 1
    fi
done < "list.txt"
