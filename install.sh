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
        reflector --country "${mirror_locations}" --latest 8 -p https --save reflector-result.txt
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
