#!/bin/bash

# ==============================================================================
# Script: ram_monitor.sh
# Description: Checks RAM usage and logs a warning if it exceeds 85%.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
LOG_FILE="/var/log/monitor/ram_monitor.log"
THRESHOLD=85

# Check if log directory exists, exit if it does not
if [ ! -d "/var/log/monitor" ]; then
    echo "Error: Directory /var/log/monitor does not exist." >&2
    exit 1
fi

# Retrieve total and used RAM in MB
# The command read assigns the output of awk to TOTAL_RAM and USED_RAM
read -r TOTAL_RAM USED_RAM <<< $(free -m | awk 'NR==2 {print $2, $3}')

# Validate that we successfully retrieved numerical values
if ! [[ "$TOTAL_RAM" =~ ^[0-9]+$ ]] || ! [[ "$USED_RAM" =~ ^[0-9]+$ ]]; then
    echo "Error: Failed to retrieve RAM usage correctly." >&2
    exit 1
fi

# Avoid division by zero
if [ "$TOTAL_RAM" -eq 0 ]; then
    echo "Error: Total RAM is reported as 0." >&2
    exit 1
fi

# Calculate the percentage of RAM used
PERCENTAGE=$(( USED_RAM * 100 / TOTAL_RAM ))

# Compare RAM usage against the threshold
if [ "$PERCENTAGE" -gt "$THRESHOLD" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Calculate values in GB for the log message format
    TOTAL_G=$(awk "BEGIN {printf \"%.1f\", $TOTAL_RAM/1024}")
    USED_G=$(awk "BEGIN {printf \"%.1f\", $USED_RAM/1024}")
    
    echo "[$TIMESTAMP] WARNING: RAM usage at ${PERCENTAGE}% (${USED_G}G/${TOTAL_G}G used)" >> "$LOG_FILE"
fi
