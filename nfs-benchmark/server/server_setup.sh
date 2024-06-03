#!/usr/bin/env bash

set -e

SHARED_DIR="/exports"

sudo yum -y makecache

sudo amazon-linux-extras install -y epel
sudo yum install -y atop curl ca-certificates openssl procps nfs-utils

sudo rm -rf $SHARED_DIR
sudo mkdir -p $SHARED_DIR
sudo chmod -R 777 $SHARED_DIR

sudo /bin/bash start-nfs-atop.sh $SHARED_DIR &