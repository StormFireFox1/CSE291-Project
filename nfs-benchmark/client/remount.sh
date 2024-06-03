#!/usr/bin/env bash

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <server-ip>"
    exit 1
fi

SHARED_DIR="$HOME/shared"
sudo umount "$SHARED_DIR"
rm -rf $SHARED_DIR
mkdir $SHARED_DIR
sudo mount -t nfs $1:/exports $SHARED_DIR
