#!/usr/bin/env bash

sudo apt update
sudo apt install build-essential

sudo apt install pkg-config
sudo apt install libnfs-dev 

git clone https://github.com/axboe/fio.git

cd fio
./configure --enable-libnfs
make
sudo make install
cd ..
rm -rf fio
fio --version
