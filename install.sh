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
