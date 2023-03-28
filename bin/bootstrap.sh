#!/bin/sh
set -aeu
BRANCH=master
# wget -O /tmp/bootstrap.sh https://raw.githubusercontent.com/stvstnfrd/its-package/${BRANCH}/dist/${ID}/${VERSION_CODENAME}/Bootstrap.sh && less /tmp/bootstrap.sh && sh /tmp/bootstrap.sh
command_exists() {
	command -v "${1}" >/dev/null 2>&1
}
sudo() {
	if command_exists sudo
	then
		command sudo "${@}"
	else
		"${@}"
	fi
}

if [ -e /etc/os-release ]
then
	# shellcheck disable=SC1091
	. /etc/os-release
else
	if [ "${ID:-}" = '' ] || [ "${VERSION_CODENAME:-}" = '' ]
	then
		echo 'Your operating system does not provide an /etc/os-release file; this is uncommon.'
		echo "You'll need to set the ID and VERSION_CODENAME variables yourself, and then run this again."
		echo
		echo "For example:"
		echo
		printf '\t%s\n' 'ID=ubuntu VERSION_CODENAME=jammy bootstrap.sh'
		exit 1
	fi
fi

if ! command_exists apt-get
then
	echo "Sorry, this operating system (${PRETTY_NAME:-${NAME}}) is not supported."
	echo 'Only apt-get--powered systems are supported; Debian, Ubuntu, and related.'
	exit 1
fi

PACKAGE_NAME="${PACKAGE_NAME:-its-package}"
PACKAGE_KEY="mDMEYnrLQRYJKwYBBAHaRw8BAQdAZ/QcdESaeBuYL3JyCQ6jKsbQ7Jsf/Z0aXN558JXJApi0TXN0dnN0bmZyZCAoQSBrZXkgZm9yIG15IEdpdGh1YiBpZGVudGl0eSkgPHN0dnN0bmZyZEBub3JlcGx5LnVzZXJzLmdpdGh1Yi5jb20+iJQEExYKADwWIQRqweNqZJiWGpDT/rWA0rbXmAYIsQUCYnrLQQIbAwULCQgHAgMiAgEGFQoJCAsCBBYCAwECHgcCF4AACgkQgNK215gGCLGafgD8CvrxbCnZySkIrZw7PDL1FYBmUz0xQnUhof8ksFdc0ocBAIHu+/ILs0PSQ8rKaLoVogIiMt32sgNGGp4vtfynDgYIuDgEYnrLQRIKKwYBBAGXVQEFAQEHQAc/vVLTqIFzE3fCoeh82zJkWSYAVOTnWJUHJqj9EupTAwEIB4h4BBgWCgAgFiEEasHjamSYlhqQ0/61gNK215gGCLEFAmJ6y0ECGwwACgkQgNK215gGCLHg+QD/X6B54qBQJ6ssodSc+LtpE0/QS+R9u5rbQhfCjGzfqp0A/RXz6RoOy/OBz5/KZV+BJdZHrtoq16QCimPNBZVpQMoNuDMEYnrMlhYJKwYBBAHaRw8BAQdA4evUWPUVFihS51Md/VXLyfIJwWqjBh4HasTf7Q2smL+I9QQYFgoAJhYhBGrB42pkmJYakNP+tYDStteYBgixBQJiesyWAhsCBQkB4TOAAIEJEIDStteYBgixdiAEGRYKAB0WIQQBLCUk0DD83ixQVNmLT/RBFd0dagUCYnrMlgAKCRCLT/RBFd0dak+2AP99rOPykgd+sEc6kmVbJx+oC2Ew3bXxQG/iEDirRUReRwEAwnXUJFAnMdHUc23MXyVZNKJ/kSSuaWoBem2lrdqxlgnzrgD+KW8QvbW9wcbWRjOfNAm9nVjzJY/EPRU7Yg+WbhUaEBwA/jCGklAaWPyX479bdMxWdHrINbbya47Zsgu4NxSVoqUC"
DOCKER_PACKAGE_KEY="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"
PATH_KEYRINGS="${PATH_KEYRINGS:-/usr/local/share/keyrings}"
sudo apt-get update
sudo apt-get install --yes apt-transport-https ca-certificates
test -d "${PATH_KEYRINGS}" \
|| sudo mkdir "${PATH_KEYRINGS}" \
;
echo "deb [signed-by=/usr/local/share/keyrings/${PACKAGE_NAME}.gpg] https://raw.githubusercontent.com/stvstnfrd/${PACKAGE_NAME}/${BRANCH}/dist/${ID} ${VERSION_CODENAME} main" \
| sudo tee "/etc/apt/sources.list.d/${PACKAGE_NAME}.list"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/local/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
| sudo tee "/etc/apt/sources.list.d/docker.list"
echo "${DOCKER_PACKAGE_KEY}" \
| base64 --decode \
| sudo tee "${PATH_KEYRINGS}/docker-archive-keyring.gpg" >/dev/null \
;
echo "${PACKAGE_KEY}" \
| base64 --decode \
| sudo tee "${PATH_KEYRINGS}/${PACKAGE_NAME}.gpg" >/dev/null \
;
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes "${PACKAGE_NAME}"
sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends docker-ce docker-ce-cli
if [ "${VERSION_CODENAME}" != stretch ]; then
    # These packages are no longer supported for Debian Stretch
    # https://forums.docker.com/t/unable-to-locate-package-docker-scan-plugin/115086/3
    sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends docker-compose-plugin docker-scan-plugin
fi
# vim: nowrap
