#!/bin/bash
host_name="CubicSilicon"
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

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}" || exit 1

function setting_mirror(){
    echo "setting mirror"
    # setting mirror
    if [[ ! -e "reflector-result.txt" ]]; then
        reflector --country "${mirror_locations}" --latest 8 --sort rate -p https --save reflector-result.txt
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
    if [[ -n "${host_name}" ]]; then
        sed -i s/^host_name=.\*/host_name="${host_name}"/ \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${user_name}" ]]; then
        sed -i s/^user_name=.\*/user_name="${user_name}"/ \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${root_passwd}" ]]; then
        sed -i s/^root_passwd=.\*/root_passwd="${root_passwd}"/ \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${user_passwd}" ]]; then
        sed -i s/^user_passwd=.\*/user_passwd="${user_passwd}"/ \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${time_zone}" ]]; then
        sed -i "s|^time_zone=.*|time_zone=${time_zone}|" \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${default_locale}" ]]; then
        sed -i "s/^default_locale=.*/default_locale=${default_locale}/" \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ ${#locale_list[@]} -ne 0 ]]; then
        locale_list_str="("
        for target in "${locale_list[@]}"; do
            locale_list_str="${locale_list_str}'${target}' "
        done
        locale_list_str="${locale_list_str})"
        sed -i "s|^locale_list=.*|locale_list=${locale_list_str}|" \
            config-scripts/000-basic/files/basic.conf
    fi
}

function extract(){
    echo "extract scripts"
    (echo "${archive}" | base64 -d | tar -xz) || \
    (echo "failed to extract scripts"; exit 1)
    
    edit_basic_conf
    # TODO: scan and copy private config-scripts
}

function install_base(){
    echo "install base packages"
    if [[ -e "/mnt/root/finished.txt" ]]; then
        return
    fi
    setting_mirror
    timedatectl &&
    pacstrap -K /mnt base linux &&
    genfstab -U /mnt > /mnt/etc/fstab &&
    echo "install at $(date)" > /mnt/root/finished.txt

    echo "copy config-scripts/ to /mnt/root/"
    cp -r "${SCRIPT_PATH}/config-scripts" /mnt/root ||
    exit 1
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
            echo "invalid operation"
            echo "valid operations: extract, base, install"
            exit 1
        ;;
    esac
    
    if [[ "${state}" -ge "1" ]]; then extract; fi
    if [[ "${state}" -ge "2" ]]; then install_base; fi
    if [[ "${state}" -ge "3" ]]; then
        arch-chroot /mnt "/root/config-scripts/config-all.sh"
    fi
}
