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
    echo "extract scripts"
    (echo "${archive}" | base64 -d | tar -xz --skip-old-files) || \
    (echo "failed to extract scripts"; exit 1)
    
    edit_basic_conf
}

function install_base(){
    if [[ ! -e "/mnt/root/finished.txt" ]]; then
        setting_mirror
        echo "install base packages"
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
