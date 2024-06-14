#!/usr/bin/env bash

set -e

SHARED_DIR="/exports"

sudo yum -y makecache

sudo yum install -y nfs-utils

sudo rm -rf $SHARED_DIR
sudo mkdir -p $SHARED_DIR
sudo chmod -R 777 $SHARED_DIR

sudo /bin/bash start-nfs.sh $SHARED_DIR &