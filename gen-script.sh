#!/bin/bash

for item in config-scripts/*/action.sh; do
    chmod +x "$item"
done
chmod +x config-scripts/config-all.sh
exa -D1 config-scripts > config-scripts/list.txt

cp install-script-template.sh install.sh
echo "archive='$(tar -czO config-scripts | base64 -w0)'" >> install.sh
echo 'main "$@"' >> install.sh
chmod +x install.sh
