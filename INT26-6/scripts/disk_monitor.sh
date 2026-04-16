#!/bin/bash

# ==============================================================================
# Script: disk_monitor.sh
# Description: Checks root filesystem usage and logs a warning if it exceeds 80%.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
LOG_FILE="/var/log/monitor/disk_monitor.log"
THRESHOLD=80

# Check if log directory exists, exit if it does not
if [ ! -d "/var/log/monitor" ]; then
    echo "Error: Directory /var/log/monitor does not exist." >&2
    exit 1
fi

# Get the current disk usage percentage for the root partition
# df -h /: Get disk space usage for root
# awk: Extract the percentage value and remove the '%' sign
DISK_USAGE=$(df -h / | awk 'NR==2 {gsub("%","",$5); print $5}')

# Check if DISK_USAGE is a valid number
if ! [[ "$DISK_USAGE" =~ ^[0-9]+$ ]]; then
    echo "Error: Failed to retrieve disk usage. Value: '$DISK_USAGE'" >&2
    exit 1
fi

# Compare disk usage against the threshold
if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] WARNING: Disk usage at ${DISK_USAGE}%" >> "$LOG_FILE"
fi
