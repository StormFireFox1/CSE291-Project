#!/usr/bin/env bash

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <server-ip>"
    exit 1
fi

SHARED_DIR="$HOME/shared"
mkdir $SHARED_DIR
#umount "$SHARED_DIR"
sudo mount -t nfs $1:/home/ubuntu/shared $SHARED_DIR
sudo systemctl status nfs-client.target
