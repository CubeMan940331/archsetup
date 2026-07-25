#!/bin/bash
set -eo pipefail
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}" || exit 1
function print_info(){
    tput setaf 4
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}

print_info "install pkgs"
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
    print_info "start running ${item_name}"
    echo "start running ${item_name}" >> /var/archsetup_install.log
    chmod +x "${item}/action.sh"
    if ! (
        "${item}/action.sh" 2>&1 | tee -a /var/archsetup_install.log
    ); then
        tput setaf 1
        echo "script in ${item_name} failed"
        tput sgr0
        echo "check /var/archsetup_install.log"
        exit 1
    fi
done < "list.txt"
