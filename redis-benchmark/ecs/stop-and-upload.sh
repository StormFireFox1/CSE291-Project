#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to stop the atop process
stop_atop() {
    echo "Stopping atop process..."
    if pgrep atop > /dev/null; then
        pkill atop
        echo "atop process stopped."
    else
        echo "No atop process found."
    fi
}

# Function to rename the atop log file
rename_log_file() {
    # Get the current date in yyyymmddhhmm format
    local current_date
    current_date=$(date +'%Y%m%d%H%M')
    
    # Define the new log file name
    local new_log_file="/var/log/redis_ecs_$current_date.log"
    
    # Rename the atop log file
    if [ -f /var/log/atop.log ]; then
        mv /var/log/atop.log "$new_log_file"
        echo "Renamed atop log file to $new_log_file."
        echo "$new_log_file"
    else
        echo "No atop log file found."
        return 1
    fi
}

# Function to upload the log file to S3
upload_to_s3() {
    local log_file=$1
    echo "Uploading log file to S3..."
    if [ -x /usr/local/bin/upload_to_s3 ]; then
        /usr/local/bin/upload_to_s3 "$log_file"
        echo "Log file uploaded to S3."
    else
        echo "/usr/local/bin/upload_to_s3 script not found or not executable."
        return 1
    fi
}

# Main script execution
main() {
    stop_atop
    local renamed_log_file
    renamed_log_file=$(rename_log_file)
    upload_to_s3 "$renamed_log_file"
}

# Run the main function
main
