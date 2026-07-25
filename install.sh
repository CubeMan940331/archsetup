#!/bin/bash
host_name="archPC"
user_name="user"

user_passwd="user"
root_passwd="root"

time_zone="Asia/Taipei"

locale_list=('en_US.UTF-8 UTF-8' 'zh_TW.UTF-8 UTF-8')
default_locale="en_US.UTF-8"

mirror_locations="TW,"
mirror_list=(
    'https://archlinux.cs.nycu.edu.tw/$repo/os/$arch'
)

set -eo pipefail
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}"
function print_info(){
    local item
    tput setaf 4
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}
function print_fail(){
    local item
    tput setaf 1
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}
function print_success(){
    local item
    tput setaf 2
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}

function setting_mirror(){
    local item
    print_info "setting mirror"
    # setting mirror
    if [[ ! -e "reflector-result.txt" ]]; then
        reflector --country "${mirror_locations}" --latest 8 -p https --save reflector-result.txt
    fi
    echo "# manual mirrorlist" > mirrorlist_new.txt
    for item in "${mirror_list[@]}"; do
        echo "Server =  ${item}" >> mirrorlist_new.txt
    done
    echo "" >> mirrorlist_new.txt

    cat reflector-result.txt >> mirrorlist_new.txt
    
    if [[ ! -e "mirrorlist_bak.txt" ]]; then
        cp /etc/pacman.d/mirrorlist mirrorlist_bak.txt
    fi
    cp mirrorlist_new.txt /etc/pacman.d/mirrorlist
}

function edit_basic_conf(){
    # only edit if the value empty
    sed -i s/^host_name="[ ]*"\$/host_name="${host_name}"/ \
        config-scripts/000-basic/files/basic.conf

    sed -i s/^user_name="[ ]*"\$/user_name="${user_name}"/ \
        config-scripts/000-basic/files/basic.conf

    sed -i s/^root_passwd="[ ]*"\$/root_passwd="${root_passwd}"/ \
        config-scripts/000-basic/files/basic.conf
    
    sed -i s/^user_passwd="[ ]*"\$/user_passwd="${user_passwd}"/ \
        config-scripts/000-basic/files/basic.conf

    sed -i "s|^time_zone=[ ]*\$|time_zone=${time_zone}|" \
        config-scripts/000-basic/files/basic.conf

    sed -i "s/^default_locale=[ ]*\$/default_locale=${default_locale}/" \
        config-scripts/000-basic/files/basic.conf

    local target
    local locale_list_str
    locale_list_str="("
    for target in "${locale_list[@]}"; do
        locale_list_str="${locale_list_str}'${target}' "
    done
    locale_list_str="${locale_list_str})"
    sed -i "s|^locale_list=[ ]*([ ]*)[ ]*\$|locale_list=${locale_list_str}|" \
        config-scripts/000-basic/files/basic.conf

}

function extract(){
    print_info "extract scripts"
    echo "${archive}" | base64 -d | tar -xz --skip-old-files
    edit_basic_conf
}

function install_base(){
    if [[ -e "/mnt/root/finished.txt" ]]; then
        echo "/mnt/root/finished.txt found"
        echo "skip running pacstrap"
        return
    fi
    setting_mirror
    print_info "install base packages"
    
    timedatectl
    pacstrap -K /mnt base linux
    genfstab -U /mnt > /mnt/etc/fstab
    echo "install at $(date)" > /mnt/root/finished.txt
}

function install_all(){
    print_info "copy config-scripts/ to /mnt/root/"
    cp -r "${SCRIPT_PATH}/config-scripts" /mnt/root
    
    arch-chroot /mnt "/root/config-scripts/config-all.sh"
    ret=$?
    rm -rf "/mnt/root/config-scripts"
    if [[ ret -ne 0 ]]; then exit 1; fi
}

function main(){
    local state
    state="$1"
    if [[ -z "${state}" ]]; then
        # default operation: install
        state="install"
    fi

    case "${state}" in
        extract | 1) state="1" ;;
        base    | 2) state="2" ;;
        install | 3) state="3" ;;
        *)
            print_fail "invalid operation"
            echo "valid operations: extract, base, install"
            exit 1
        ;;
    esac
    
    if [[ "${state}" -ge "1" ]]; then extract; fi
    if [[ "${state}" -ge "2" ]]; then install_base; fi
    if [[ "${state}" -ge "3" ]]; then
        install_all
        print_success "Installation Finish!"
    fi
}
archive='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'
main "$@"
