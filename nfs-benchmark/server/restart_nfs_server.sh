#!/usr/bin/env bash

set -e

SHARED_DIR="$HOME/shared"

rm -rf $SHARED_DIR
sudo mkdir $SHARED_DIR
sudo chown nobody:nogroup shared
sudo chmod -R 777 shared
head -c 1G /dev/urandom > "$SHARED_DIR/testfile"

sudo sed -i '$d' /etc/exports
if [ "$1" -eq 1 ]; then
	echo "$SHARED_DIR *(rw,sync,insecure,all_squash,no_subtree_check,anonuid=1000,anongid=1000)" | sudo tee -a /etc/exports > /dev/null
else
	echo "$SHARED_DIR *(rw,async,insecure,all_squash,no_subtree_check,anonuid=1000,anongid=1000)" | sudo tee -a /etc/exports > /dev/null
fi
sudo exportfs -a
sudo systemctl restart nfs-kernel-server 
sudo systemctl status nfs-server
