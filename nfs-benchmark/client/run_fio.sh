#!/usr/bin/env bash

set -e

if [ "$#" -lt 5 ]; then
    echo "Usage: $0 <server-ip> <filename> <mode:randrw/randread/randwrite> <sync:0/1> <size>"
    exit 1
fi

SHARED_DIR="$HOME/shared"

rm -rf "$HOME/nfs_logs/$FILENAME-$MODE-io.log"
rm -rf "$HOME/$FILENAME-$MODE-fio-result"

IP=$1
FILENAME=$2
MODE=$3
SYNC=$4
SIZE=$5

FIO_FILE="$SHARED_DIR/$MODE-job-file.fio"
rm -rf $FIO_FILE

echo "[global]" >> "$FIO_FILE"
echo "ioengine=nfs" >> "$FIO_FILE"
echo "nfs_url=nfs://$IP/home/ubuntu/shared" >> "$FIO_FILE"

if [ "$SYNC" -eq 1 ]; then
    echo "direct=1" >> "$FIO_FILE"
fi

echo "[file-write]" >> "$FIO_FILE"
echo "readwrite=$MODE" >> "$FIO_FILE"
echo "filename=$FILENAME" >> "$FIO_FILE"
echo "write_iolog=$HOME/nfs_logs/$FILENAME-$MODE-io.log" >> "$FIO_FILE"
echo "size=$SIZE" >> "$FIO_FILE"

if [ "$SYNC" -eq 1 ]; then
    echo "sync=sync" >> "$FIO_FILE"
fi

fio $FIO_FILE --output="$HOME/$FILENAME-$MODE-fio-result" --output-format=json
