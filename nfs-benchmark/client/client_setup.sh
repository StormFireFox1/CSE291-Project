#!/usr/bin/env bash

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <server-ip>"
    exit 1
fi

sudo apt update

sudo apt install -y nfs-common build-essential pkg-config libnfs-dev 

git clone https://github.com/axboe/fio.git

cd fio
./configure --enable-libnfs
make
sudo make install
cd ..
rm -rf fio
fio --version

SHARED_DIR="$HOME/shared"
sudo mkdir $SHARED_DIR
sudo mount -t nfs $1:/exports $SHARED_DIR
sudo systemctl status nfs-client.target
