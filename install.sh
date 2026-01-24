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
