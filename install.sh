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
