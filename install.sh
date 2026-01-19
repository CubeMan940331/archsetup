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
archive='H4sIAAAAAAAAA+1cbXPbuBH2Z/wKRHbt+DoQXyRS7d0pV8fJ5NLmkkycdDp1fRqKBEVGJMESoCQnl//eBUjJshxZiaPQaYxnxhbxDnKBB7sLkD7LwnhEuF/EueDGzteACeg5jvy1eo65/DvHjuVYnU7Hcnpdd8e0Oq7t7mDnq/RmBSUXXoHxjl8Oaepla/NtSv8/hX9Z/pZpEs6j7Y6DT5a/bTmmI+Xf7Vm2ln8TWCP/fDxqi5nYThtSwG63u17+trUif9e2nR1sbqf563HH5c9ymoHAUejFiT30MnTbHdJoFGvmv+eLmGVtHm2jjU387zir/O86cv3X8//rY/eeMYwzY+gBB5wcv3r68vXg5dHrX/utvft+gOF/EBeZl1K4fP/w6OTXwcmLN6+OH5+aZx9ahy28v4/zaXDYQirz+6UaPrTwH39gOosFthB6fvTb4/7efWiGzmtbyYs5DTCh+IAbv5+a5K9nPxDDGB0cIupHDLeklARUR/1SxNkI772XVX7A1cBtIbRbX+L+xwEZfJaf4zBOKPJz9csNGOtBO2G+l2CDCt+Y06DxFi7agQE3KKuGTg8TCl0sJrFPET/ngqa+SBYJUI3MeiXhm6fVNfO/ejpbauPz9T8XVECt/zWBa+V/MTu+qI1N+p/ldlbk3+v1LM3/TeBUyvgMVXQV4D4WRUkRiF/QAkIyFQF/VfoARMAokTk5RPpjmskSFekFKPVmBRXFOUQ5UEMWiBiYvo+tSNZQB5zom6XCO4mV+Q+TkYyKcrhVB8Dn8z/8aP5vBOvkv00HwEb7v2Ovrv8dzf/NQAobMU7ygg1pgWgYDxkT6ajQNH0nsG7+b9MBsIH/LdO9ov+7rvb/NYK7Y//LYU3iDCpKEvwfhAGEQK0jKvqzv7gDt0uA/RYpcE3g3qkvWHHeNyQrLtJkIGFeQAsSB31ZsTT+v24D86SCpmyifAvSNZGOoQpM8sp7EdDQKxNhyAJt5ZBYODpqim/74WhdXtX/dFwxAiYMqz6pDFUuKKtXhe8M6/h/mw6gG/h/LEfv/zaC6+W/xBpf0MZm/d+5LH/btC3t/28ET169eTh49PTk6OGzx4MXJ4OXr148fPyqH3oJp5rsv3+szP86CBrMlvb+JDbp/7Zb7/93Xdvt9dT+v6nnfyNoSP+vlPi5cpyPR7yFcs+HB4rJCWi1GVMjr0jlNaUBVW37nsBt44e5MwqMhFFBc0wm+OD33QNotaq2hR9gY+IVhlf4EaeizAd1S+2EjdA0grUMF9QD+6LAsaDpTzhgSp2WgYG8vcu2iYy+ziRRRUN8iu/J5Cr/hcXcwmc/YRHRTOWTgHsDo6WkKiKM1U/V9b33iy4oI0hQiol33d2o+qKUBfjPs3n5D0uNzzt3D99ftP+RbNh+sG99coOHKzdU22SVwRVneG9xF2rHkwatlax+RP3xNa0s5a9GTP2kApZR/DNuJTEXcgi09Jq0Xazwv2OaZMJ9FtAt7gDcwP/fNbX/vxGsl//2PICb5N+94v/r2bap1/8mcHf8fwtXWJkHnqD1MMdGyQv5CKQHbH69kgW0i4BOjKxMku9u+Vk//7fnAbqB/8cxtf+nEWyS/6WZcMM2NvK/5a74fyzb1PzfCJb5f5lpBQMbaZrJTQj8z5NjSYNScY8nFLi+LBKw01gp8lLIPQxsiBTMMukrBAONczKER0pe/P0ZPoiEyPmPhiGHT3sS89JLuCiDmLV9lho88ox5M78MyzgJ+lydL9pnvJ+AyTQjM7d7gKSIyLtZqBpSdZEq3w9tSGqP3mFyXDE51FiorZEELEu+FGdUd0EWtRqX6F+Fvjt234yV+T+3s7baxkb/b89c+H96liX1f+ACPf+bADx9mK089tHc9Y9MyySgZCUc1adBEbAx+cejx+hidbiDM+X7xOr+z1z22zwAeAP734bsWv9rAGvlv8UDgJv43+nZi/d/u7alzv9o/a8Z7GIwbWkC+h5L5KFuTomKQKNYSKNaWQHqgHedJWA85NUlnYWekDofR5kIOemMZAlBZ2CoB7FgBZrEqYySbn4vC3CchQzn3ogiiCHBUP3IMEdQSqYqOz6iSYLf/Ev2JiKgJuYJla4oJNJyBo16MlNGxZQVY1wtVBAiVZ+kboqmIypQnNMi7CDh50GZ5ki9/5PmUj2VJ9mrcu9ilVDfIIwEUfI6KRIsR8MUms38oEShx0VIhR+p+4m5j6Q6PD/uM58/aOgjP/VEEc+Qz6bcO0cwu6D7iCfy5aAhzaCGacRi/o2soFf2/2t14Jb5H9I1/zeBtfJvkP+lsK+8/6n1/0awi5W4gZX9sSJiuQQgZSQjXgaKkI9fvgHK8wumNH8vDUipruJM0KS+VktFkU7B0q5Kk0Xwgq1R/QvPEdrSR8y/Aayd/1s8AL7p/Ie7+P6LY7qmI/d/TH3+oxncnf0fzsrCh5Yrv7Ya5G05+lXZ13FK/80yWrkNw2W/4TuIlqqpAX2WLzEOZAT0WJ2iVi/HylgUTX0IjDEhUptkkS+rVckUhaw6dyKPSkAtVexA+tpO/wbPcXEcZekR7B7MD220DoxL1/VJcImflzpB2yOaLaU9qHylS2n7+yoxnVxJWalFnbpAVZjIcC2DZ0fPn/T33tcnxwdVhg/q9M1SBfKZynuPGBdS1mh+0kVGzE+61EUWeSB/IQ/A5x7n02BRRMYNqjg1RqpL6diVKbKUFwS45LCWyH8yQNIneBpRMGmgvIysm1zUqeI+WudKgatv8z+vlq/f6uVr5fS9XC5pweuvBlx8YgCiCadCDlu+mvPWl8C1/L/FA+Cfrv/bTrdnq/f/TP39p0awQf4XNPkFbWzS/+3F959q+dum/v5TQ1ha+haLW39p6Vpaq/r3D9Fl7u9f4vkFv6toyaQqekGpKrom+CVi76MlRu7fOiHeMWyY/5cWr5u2sXH/b/X9b9sy9fxvBn+qdKWjZ8/69+Hfj/B3iGVQT8Q7gZX5X+/03vr3Px1QCbT+1wDWyL/R7392XPfK978cvf/XCEAjK+iEZmB6FyyFISBPfoGlzKWTRb6ng/I4p9O4oOSt54/Rf4VL0lK5PILYI2GY5nSEMiYYCVkm+NIl8d+OEcoTj6ce4kGgtgKfvHmKvTznaMwyzkDBDFiSR3GGQmgiZDPEcwqWOglinnvCj8DMHk1pNonpFE0SH43kzqLyNvuxmDno0g+B/FPo+Dw4LCh9RxeJaqjLbUK9ti2wZv43+v1P1776/Z+O1v8awd3x/8oX9uZv7FVeOKAk5dpoB0YLny2/tLfi2FvKCDyFPv4pUSicVt7Pq6U+9TOikiSblf+a+X/L3/90XLuj9b8mcK38L4b0F7Wx0f53Vvf/e06vq/m/CZy+ljI+Q49A30q88xOgJlr0p9554mUBOi6LAnTDfq1I3XZnNTQ0NDQ0NDQ0NDQ0NDQ0NDQ0ND4L/wPqtQ57AHgAAA=='
main "$@"
