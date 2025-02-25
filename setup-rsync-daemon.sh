#!/bin/bash

# Script to set up an rsync daemon for mirroring log files

# Function to prompt for input
prompt() {
    read -p "$1: " input
    echo "$input"
}

# Ask for user information
RSYNC_USER=$(prompt "Enter the username for rsync access")
RSYNC_PASSWORD=$(prompt "Enter the password for rsync access")
SOURCE_PATH=$(prompt "Enter the path to the log files (e.g., /var/log)")

# Ask for the destination path and ensure it exists
while true; do
    DESTINATION_PATH=$(prompt "Enter the destination path for mirroring (e.g., /backup/logs)")
    if [ -d "$DESTINATION_PATH" ]; then
        echo "The destination folder already exists."
        break
    else
        echo "The destination folder does not exist. Would you like to create it? (y/n)"
        read -r create_dir
        if [[ "$create_dir" == "y" ]]; then
            mkdir -p "$DESTINATION_PATH"
            echo "The destination folder has been created."
            break
        else
            echo "Please provide a valid destination folder."
        fi
    fi
done

# Ask for server details
SERVER_IP=$(prompt "Enter the IP address or hostname of the server")

# Create the rsync configuration file
RSYNC_CONF="/etc/rsyncd.conf"
echo "uid = nobody" > $RSYNC_CONF
echo "gid = nogroup" >> $RSYNC_CONF
echo "use chroot = no" >> $RSYNC_CONF
echo "max connections = 10" >> $RSYNC_CONF
echo "log file = /var/log/rsync.log" >> $RSYNC_CONF
echo "timeout = 300" >> $RSYNC_CONF
echo "" >> $RSYNC_CONF
echo "[logfiles]" >> $RSYNC_CONF
echo "path = $SOURCE_PATH" >> $RSYNC_CONF
echo "comment = Log files mirror" >> $RSYNC_CONF
echo "read only = yes" >> $RSYNC_CONF
echo "list = yes" >> $RSYNC_CONF
echo "auth users = $RSYNC_USER" >> $RSYNC_CONF
echo "secrets file = /etc/rsyncd.secrets" >> $RSYNC_CONF

# Create the secrets file for authentication
SECRETS_FILE="/etc/rsyncd.secrets"
echo "$RSYNC_USER:$RSYNC_PASSWORD" > $SECRETS_FILE
chmod 600 $SECRETS_FILE

# Start the rsync daemon
echo "Starting the rsync daemon..."
sudo rsync --daemon

# Set up a cron job for mirroring
CRON_JOB="0 * * * * rsync -avz $RSYNC_USER@$SERVER_IP::logfiles $DESTINATION_PATH"
(crontab -l; echo "$CRON_JOB") | crontab -

echo "The setup of the rsync daemon has been completed."
echo "Log files will now be mirrored to $DESTINATION_PATH every hour."
