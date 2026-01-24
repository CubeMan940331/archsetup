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
    if [[ -e "/mnt/root/finished.txt" ]]; then
        echo "/mnt/root/finished.txt found"
        echo "skip running pacstrap"
        return
    fi
    setting_mirror
    echo "install base packages"
    
    timedatectl &&
    pacstrap -K /mnt base linux &&
    genfstab -U /mnt > /mnt/etc/fstab &&
    echo "install at $(date)" > /mnt/root/finished.txt ||
    exit 1
}

function install_all(){
    echo "copy config-scripts/ to /mnt/root/"
    cp -r "${SCRIPT_PATH}/config-scripts" /mnt/root ||
    exit $?
    
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
            echo "invalid operation"
            echo "valid operations: extract, base, install"
            exit 1
        ;;
    esac
    
    if [[ "${state}" -ge "1" ]]; then extract; fi
    if [[ "${state}" -ge "2" ]]; then install_base; fi
    if [[ "${state}" -ge "3" ]]; then
        install_all
        tput setaf 2
        echo "Installation Finish!"
        tput sgr0
    fi
}
archive='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'
main "$@"
