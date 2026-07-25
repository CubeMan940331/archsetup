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
