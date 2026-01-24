#!/usr/bin/env sh
for item in config-scripts/*/action.sh; do
    chmod +x "$item"
done
chmod +x config-scripts/config-all.sh
find config-scripts -depth 1 -type d | \
    sed -e 's:^config-scripts/::' -e 's:/$::' | \
    sort > config-scripts/list.txt

cp install-script-template.sh install.sh
echo "archive='$(tar -cf - config-scripts/ | gzip -9 | base64 -w0)'" >> install.sh
echo 'main "$@"' >> install.sh
chmod +x install.sh
