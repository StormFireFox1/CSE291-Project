#!/bin/bash

set -e

if [ $# -lt 2 ]; then
    echo "Insufficient arguments passed!"
    echo "Usage: ./upload-fio.sh <SERVICE> <FILE>"
    exit 1
fi

SERVICE=$1
DATE=$(date +'%Y%m%d%H%M')
FILE="/var/log/fio_nfs_${SERVICE}_${DATE}.json"

mv $2 $FILE

# Function to upload file to S3
upload_to_s3() {
    FILE=$1

    HOST="minio.matei.lol"
    S3_KEY="CMn7XfKcY0hxnXfJlHgU"
    S3_SECRET="WIDd7QZmssxLVQD2W7QvNllseKJ1JRdMfKsykBCM"
    BUCKET="cse-291"

    BASE_FILE=$(basename ${FILE})
    RESOURCE="/${BUCKET}/${BASE_FILE}"
    CONTENT_TYPE="application/octet-stream"
    UPLOAD_DATE=$(date -R)
    _signature="PUT\n\n${CONTENT_TYPE}\n${UPLOAD_DATE}\n${RESOURCE}"
    SIGNATURE=$(echo -en ${_signature} | openssl sha1 -hmac ${S3_SECRET} -binary | base64)

    curl -v -X PUT -T "${FILE}" \
        -H "Host: $HOST" \
        -H "Date: ${UPLOAD_DATE}" \
        -H "Content-Type: ${CONTENT_TYPE}" \
        -H "Authorization: AWS ${S3_KEY}:${SIGNATURE}" \
        https://$HOST${RESOURCE}
}

echo "Uploading log file to S3..."
if upload_to_s3 "$FILE"; then
    echo "Log file uploaded to S3."
else
    echo "Failed to upload log file to S3."
    exit 1
fi
