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
