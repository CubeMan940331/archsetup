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
    # only edit if the value empty
    if [[ -n "${host_name}" ]]; then
        sed -i s/^host_name=\$/host_name="${host_name}"/ \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${user_name}" ]]; then
        sed -i s/^user_name=\$/user_name="${user_name}"/ \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${root_passwd}" ]]; then
        sed -i s/^root_passwd=\$/root_passwd="${root_passwd}"/ \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${user_passwd}" ]]; then
        sed -i s/^user_passwd=\$/user_passwd="${user_passwd}"/ \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${time_zone}" ]]; then
        sed -i "s|^time_zone=\$|time_zone=${time_zone}|" \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ -n "${default_locale}" ]]; then
        sed -i "s/^default_locale=\$/default_locale=${default_locale}/" \
            config-scripts/000-basic/files/basic.conf
    fi
    if [[ ${#locale_list[@]} -ne 0 ]]; then
        locale_list_str="("
        for target in "${locale_list[@]}"; do
            locale_list_str="${locale_list_str}'${target}' "
        done
        locale_list_str="${locale_list_str})"
        sed -i "s|^locale_list=\([ ]*\)\$|locale_list=${locale_list_str}|" \
            config-scripts/000-basic/files/basic.conf
    fi
}

function extract(){
    echo "extract scripts"
    (echo "${archive}" | base64 -d | tar -xz --skip-old-files) || \
    (echo "failed to extract scripts"; exit 1)
    
    edit_basic_conf
}

function install_base(){
    echo "install base packages"
    if [[ ! -e "/mnt/root/finished.txt" ]]; then
        setting_mirror
        timedatectl &&
        pacstrap -K /mnt base linux &&
        genfstab -U /mnt > /mnt/etc/fstab &&
        echo "install at $(date)" > /mnt/root/finished.txt
    fi

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
archive='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'
main "$@"
