#!/bin/bash

set -e

if [ $# -eq 0 ]; then
	echo "No service name passed!"
	echo "Usage: ./benchmark_hashcat <SERVICE>"
	exit 1
fi

SERVICE=$1
DATE=$(date +'%Y%m%d%H%M')
FILE="/var/log/redis_profile_${SERVICE}_${DATE}.log"

echo "Stopping atop process..."
if pgrep atop > /dev/null; then
    pkill atop
    echo "atop process stopped."
else
    echo "No atop process found."
    exit 1
fi

if [ -f /var/log/atop.log ]; then
    mv /var/log/atop.log "$FILE"
    echo "Renamed atop log file to $FILE."
else
    echo "No atop log file found."
    exit 1
fi

echo "Uploading log file to S3..."
if /usr/local/bin/upload_to_s3 "$FILE"; then
    echo "Log file uploaded to S3."
else
    echo "/usr/local/bin/upload_to_s3 script not found or not executable."
    exit 1
fi
