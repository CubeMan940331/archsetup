#!/usr/bin/env bash
mirror_site="https://fastly.mirror.pkgbuild.com/iso/latest/"

set -eo pipefail
function print_fail(){
    local item
    tput setaf 1
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}
function print_success(){
    local item
    tput setaf 2
    for item in "$@"; do echo "${item}"; done
    tput sgr0
}
get_checksum_file(){
    curl -sO "${mirror_site}/sha256sums.txt"
    entry=$(grep -E 'archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64.iso' sha256sums.txt)
    h_ref=$(echo "$entry" | grep -Eo '^[0-9a-f]{64}')
    filename=$(echo "$entry" | tail -c 32)
}
check_file(){
    if [ ! -e "$filename" ]; then
        print_fail "File not Found"
        return 1
    fi
    h_cmp=$(openssl dgst -sha256 "$filename" | grep -Eo '[0-9a-f]{64}$')
    if [ "$h_cmp" != "$h_ref" ]; then
        print_fail "CHecksum Error"
        return 1
    fi
    print_success "Done"
    return 0
}
main(){
    get_checksum_file
    while ! check_file; do
        curl -O "${mirror_site}/${filename}"
    done
}

main
