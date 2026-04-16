#!/bin/bash

# ==============================================================================
# Script: log_watcher.sh
# Description: Monitors disk and RAM logs for WARNINGs and sends email alerts.
# ==============================================================================

# Exit immediately if a pipeline fails
set -o pipefail

# Define variables
DISK_LOG="/var/log/monitor/disk_monitor.log"
RAM_LOG="/var/log/monitor/ram_monitor.log"
EMAIL_LOG="/var/log/monitor/email_notifications.log"
ALERT_EMAIL="maksimec10@gmail.com"
SENDER_EMAIL="service@server.maksimecv.pp.ua"
HOSTNAME=$(hostname)

# Ensure log directory and files exist
if [ ! -d "/var/log/monitor" ]; then
    echo "Error: Directory /var/log/monitor does not exist." >&2
    exit 1
fi

touch "$DISK_LOG" "$RAM_LOG" "$EMAIL_LOG"

# Watch the log files continuously
# Note: Using set -e here would cause the script to exit if grep fails to find a match,
# so we handle errors within the loop instead.
tail -F "$DISK_LOG" "$RAM_LOG" | while read -r line; do
    
    # Check if the line contains "WARNING"
    if echo "$line" | grep -q "WARNING"; then
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        MESSAGE="[$TIMESTAMP] Host: $HOSTNAME - Event: $line"
        
        # Log the notification locally
        echo "$MESSAGE" >> "$EMAIL_LOG"
        
        # Send the email notification
        # If mail fails, print an error but do not stop the script
        if ! echo "$MESSAGE" | mail -s "System Monitor Warning - $HOSTNAME" -a "From: $SENDER_EMAIL" "$ALERT_EMAIL"; then
            echo "Error: Failed to send email alert for event: $line" >&2
        fi
    fi
    
done
