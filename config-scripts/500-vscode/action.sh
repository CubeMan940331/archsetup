#!/bin/bash
set -eo pipefail
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_PATH}"
NAME=$(basename "${SCRIPT_PATH}" | sed -e 's/^[0-9]*-//g')
# script =======================
cp files/update-vscode /usr/bin
chmod +x /usr/bin/update-vscode
/usr/bin/update-vscode
