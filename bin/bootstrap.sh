#!/bin/sh
set -aeu
# . /etc/os-release && wget -O /tmp/bootstrap.sh https://raw.githubusercontent.com/stvstnfrd/its-package/master/dist/${ID}/${VERSION_CODENAME}/Bootstrap.sh && less /tmp/bootstrap.sh && sh /tmp/bootstrap.sh

cat <<EOS
#!/usr/bin/env sh
set -aeu
ID="\${ID:-${ID}}"
CODENAME="\${CODENAME:-${CODENAME}}"
PACKAGE_NAME="\${PACKAGE_NAME:-its-package}"
PATH_KEYRINGS="\${PATH_KEYRINGS:-/usr/local/share/keyrings}"
test -d "\${PATH_KEYRINGS}" \\
|| sudo mkdir "\${PATH_KEYRINGS}" \\
;
echo "deb [signed-by=/usr/local/share/keyrings/\${PACKAGE_NAME}.gpg] https://raw.githubusercontent.com/stvstnfrd/\${PACKAGE_NAME}/master/dist/\${ID}/\${CODENAME} ./" \\
| sudo tee "/etc/apt/sources.list.d/\${PACKAGE_NAME}.list"
sudo wget -O "\${PATH_KEYRINGS}/\${PACKAGE_NAME}.gpg" "https://raw.githubusercontent.com/stvstnfrd/\${PACKAGE_NAME}/master/dist/\${ID}/\${CODENAME}/Key.gpg"
sudo apt-get update
sudo apt-get install "\${PACKAGE_NAME}"
EOS
