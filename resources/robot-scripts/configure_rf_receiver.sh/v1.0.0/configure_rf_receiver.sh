#!/bin/bash

# Define the log file
LOG_FILE="/var/log/usb-device-monitor.log"
DEVICE="/dev/DEV-RF-RECEIVER"

# Function to log messages with a timestamp
log_message() {
    local message=$1
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp: $message" >> "$LOG_FILE"
}

# Load kernel modules if not already loaded
load_modules() {
    modprobe serio
    modprobe fsia6b
}

# Function to start inputattach if not already running
start_inputattach() {
    if ! pgrep -x "inputattach" > /dev/null; then
        log_message "Starting inputattach for RF receiver."
        inputattach --fsia6b "$DEVICE" &
        log_message "inputattach started for RF receiver."
    else
        log_message "inputattach is already running."
    fi
}

DEVICE_PRESENT=false

while true; do
    if [ -e "$DEVICE" ]; then
        if [ "$DEVICE_PRESENT" = false ]; then
            log_message "RF receiver connected."
            DEVICE_PRESENT=true
            load_modules
            start_inputattach
        fi
    else
        if [ "$DEVICE_PRESENT" = true ]; then
            log_message "RF receiver disconnected."
            DEVICE_PRESENT=false
            pkill -x "inputattach"
        fi
    fi
    sleep 5  # Check every 5 seconds
done
