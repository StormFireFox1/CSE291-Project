#!/bin/bash

head -c 2G /dev/urandom > "$1/testfile"

# Start atop in the background
atop -w /var/log/atop.log -a 5 &

# Start Redis server with the custom configuration file
/bin/bash /usr/local/bin/run_nfs.sh $1