#!/bin/bash

# Start atop in the background
atop -a 5 -w /var/log/atop.log &

# Start Redis server with the custom configuration file
redis-server /usr/local/etc/redis/redis.conf
