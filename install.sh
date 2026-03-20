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
