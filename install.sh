#!/bin/sh

TMP_NAME="/tmp/$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)"

if which curl >/dev/null; then
    set -- curl -L --progress-bar -o "$TMP_NAME"
    LATEST=$(curl -sL https://api.github.com/repos/cryon-io/ami/releases/latest | grep tag_name | sed 's/  "tag_name": "//g' | sed 's/",//g')
else
    set -- wget -q --show-progress -O "$TMP_NAME"
    LATEST=$(wget -qO- https://api.github.com/repos/cryon-io/ami/releases/latest | grep tag_name | sed 's/  "tag_name": "//g' | sed 's/",//g')
fi

# install eli
echo "Downloading eli setup script..."
if ! "$@" https://raw.githubusercontent.com/cryon-io/eli/master/install.sh; then
    echo "Failed to download eli, please retry ... "
    exit 1
fi
if ! sh "$TMP_NAME"; then
    echo "Failed to download eli, please retry ... "
    exit 1
fi

# install ami
echo "Downloading ami $LATEST..."
if "$@" "https://github.com/cryon-io/ami/releases/download/$LATEST/ami.lua" &&
    mv "$TMP_NAME" /usr/sbin/ami &&
    chmod +x /usr/sbin/ami; then
    echo "ami $LATEST successfuly installed."
else
    echo "ami installation failed!" 1>&2
    exit 1
fi
