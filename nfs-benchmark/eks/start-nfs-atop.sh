#!/bin/bash

head -c 2G /dev/urandom > /exports/testfile

# Start atop in the background
atop -w /var/log/atop.log -a 5 &

# Start Redis server with the custom configuration file
/bin/bash /usr/local/bin/run_nfs.sh $@