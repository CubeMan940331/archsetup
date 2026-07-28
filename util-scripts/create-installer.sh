#!/usr/bin/env bash
set -eo pipefail

if [ $# -ne 2 ]; then
    echo "usage: $0 path_to_image path_to_partition"
    exit 1
fi
if [ "$(id -u)" -ne 0 ]; then
    echo "this script requires root permissoin"
    exit 1
fi

mkfs.fat -F 32 "$2"
tmp_dir="$(mktemp -d)"
mount "$2" "${tmp_dir}"
bsdtar -x -f "$1" -C "${tmp_dir}"
umount "${tmp_dir}"
rm -r "${tmp_dir}"
