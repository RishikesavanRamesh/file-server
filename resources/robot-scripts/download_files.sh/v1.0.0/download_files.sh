#!/bin/bash

# Define log file
LOG_FILE="file_download_log.txt"

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." | tee -a $LOG_FILE
    exit 1
fi

# Clear the log file
echo "Log started at $(date)" > $LOG_FILE

# Define a function for printing messages
log_message() {
    local message="$1"
    local type="$2"
    local separator=""
    
    case "$type" in
        "info")
            echo -e "[INFO] $message" | tee -a $LOG_FILE
            ;;
        "file_download")
            echo -e "[${filename}] Downloading file from $file_url $separator" | tee -a $LOG_FILE
            ;;
        "checksum_download")
            echo -e "[${filename}] Downloading checksum from $checksum_url $separator" | tee -a $LOG_FILE
            ;;
        "success")
            echo -e "[${filename}] $message" | tee -a $LOG_FILE
            ;;
        "error")
            echo -e "Error: $message" | tee -a $LOG_FILE
            ;;
        "checksum")
            echo -e "[${filename}] Checksum verification $separator" | tee -a $LOG_FILE
            ;;
        "checksum_success")
            echo -e "[${filename}] Checksum verification successful! (SHA-256: $actual_sha)" | tee -a $LOG_FILE
            ;;
        "checksum_fail")
            echo -e "[${filename}] Checksum verification failed! (Calculated SHA-256: $actual_sha)" | tee -a $LOG_FILE
            ;;
        *)
            echo -e "[UNKNOWN] $message" | tee -a $LOG_FILE
            ;;
    esac
}

# Read version environment variables and file information from a file
# Assume `files.txt` contains lines in the format: <path/filename> <url-for-file> <url-for-checksum>
while IFS=' ' read -r file_path file_url checksum_url; do
    # Skip lines that are empty or do not have exactly 3 fields
    if [ -z "$file_path" ] || [ -z "$file_url" ] || [ -z "$checksum_url" ]; then
        log_message "Skipping incomplete or empty line" "error"
        continue
    fi

    # Extract filename from file_path for logging purposes
    filename=$(basename "$file_path")
    dir_path=$(dirname "$file_path")

    # Create directory if it does not exist
    if [ ! -d "$dir_path" ]; then
        log_message "Creating directory $dir_path" "info"
        mkdir -p "$dir_path"
        if [ $? -ne 0 ]; then
            log_message "Failed to create directory $dir_path" "error"
            continue
        fi
    fi

    # Download the file
    log_message "Downloading file from $file_url" "file_download"
    if curl -s -o "$file_path" "$file_url"; then
        log_message "Download successful!" "success"
    else
        log_message "Error downloading from $file_url" "error"
        continue
    fi

    # Download the checksum file
    checksum_filename="${file_path}.sha256"
    log_message "Downloading checksum from $checksum_url" "checksum_download"
    if curl -s -o "$checksum_filename" "$checksum_url"; then
        log_message "Checksum file download successful!" "success"
    else
        log_message "Error downloading checksum from $checksum_url" "error"
        continue
    fi

    # Verify the file's SHA checksum
    log_message "Checksum verification" "checksum"
    # Extract checksum from the downloaded checksum file
    expected_sha=$(cat "$checksum_filename")
    actual_sha=$(shasum -a 256 "$file_path" | awk '{ print $1 }')
    if [ "$actual_sha" = "$expected_sha" ]; then
        log_message "Checksum verification successful!" "checksum_success"
    else
        log_message "Checksum verification failed!" "checksum_fail"
    fi

    # Clean up
    rm "$checksum_filename"

done < files.txt

log_message "Log ended at $(date)" "info"

