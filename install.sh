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
    tput setaf 4
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}
function print_fail(){
    tput setaf 1
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}
function print_success(){
    tput setaf 2
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}

function setting_mirror(){
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
