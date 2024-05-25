#!/usr/bin/env bash

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <server-ip>"
    exit 1
fi

sudo apt update

sudo apt install nfs-common
SHARED_DIR="$HOME/shared"
sudo mkdir $SHARED_DIR
sudo mkdir nfs_logs
sudo mount -t nfs $1:/home/ubuntu/shared $SHARED_DIR
sudo systemctl status nfs-client.target
