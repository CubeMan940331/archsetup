#!/bin/bash
set -eo pipefail
curl --output-dir ~ -O https://raw.githubusercontent.com/CubeMan940331/archsetup/refs/heads/main/install.sh
cp -r config-scripts ~
