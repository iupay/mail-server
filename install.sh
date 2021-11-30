#!/usr/bin/sh

HOSTNAME="$1"

if ! $HOSTNAME; then
    echo "Missing hostname!"
    exit 1
fi

set -e

apt-get update
apt-get upgrade -y

if ! command -v node &> /dev/null; then
    echo "\"node\" not found. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
    apt-get install -y nodejs build-essential
fi

if ! command -v yarn &> /dev/null; then
    echo "\"yarn\" not found. Installing..."
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list
    apt-get update && apt-get install -y yarn
fi

if ! command -v haraka &> /dev/null; then
    echo "\"haraka\" not found. Installing..."
    apt-get install -y python3
    yarn global add Haraka @google-cloud/pubsub

    haraka -i /haraka
    haraka -c /haraka -p gcp_pubsub

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
