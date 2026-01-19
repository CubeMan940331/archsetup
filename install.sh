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
