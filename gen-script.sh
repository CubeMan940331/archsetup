#!/bin/bash

for item in config-scripts/*/action.sh; do
    chmod +x "$item"
done

cp install-script-template.sh install.sh
echo "archive='$(tar -czO config-scripts | base64 -w0)'" >> install.sh
echo 'main "$@"' >> install.sh
chmod +x install.sh
