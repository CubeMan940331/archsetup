#!/bin/bash
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}" || exit 1

NAME=$(basename "${SCRIPT_PATH}" | sed -e 's/^[0-9]*-//g')
echo "start executing ${NAME} script"

# script =======================
cp files/update-vscode /usr/bin && 
chmod +x /usr/bin/update-vscode &&
/usr/bin/update-vscode
