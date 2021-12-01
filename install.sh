#!/usr/bin/sh

HOSTNAME="$1"
TOPICNAME="$2"

if [ -z "$HOSTNAME" ]; then
    echo "Missing hostname!"
    exit 1
fi

if [ -z "$TOPICNAME" ]; then
    echo "Missing topic name!"
    exit 1
fi

set -e

apt-get update
apt-get upgrade -y


if ! [ -x "$(command -v node)" ]; then
    echo "\"node\" not found. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
    apt-get install -y nodejs build-essential
fi

if ! [ -x "$(command -v yarn)" ]; then
    echo "\"yarn\" not found. Installing..."
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list
    apt-get update && apt-get install -y yarn
fi

if ! [ -x "$(command -v haraka)" ]; then
    echo "\"haraka\" not found. Installing..."
    apt-get install -y python3
    yarn global add Haraka @google-cloud/pubsub

    if [ -d /haraka ]; then
        rm -r /haraka
    fi

    haraka -i /haraka
    haraka -c /haraka -p gcp_pubsub

    sed -i "s/<TOPICNAME>/$TOPICNAME/g" ./haraka/gcp_pubsub.js
    mv ./haraka/gcp_pubsub.js /haraka/plugins/
    mv ./haraka/plugins /haraka/config/
    echo $HOSTNAME >> /haraka/config/host_list
fi

if [ ! -f "/etc/systemd/system/haraka.service" ]; then
    echo "Creating Haraka service..."
    mv ./haraka/haraka.service /etc/systemd/system/
    chmod u+x /etc/systemd/system/haraka.service
    systemctl enable haraka
    systemctl start haraka
fi
