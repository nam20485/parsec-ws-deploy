#!/bin/bash

# Feature Script: Mount Storage Disk to /home
# This script configures the primary storage disk to be mounted directly at /home.

set -e

echo "Starting to configure /home on the persistent storage disk..."

DATA_MOUNT_POINT="/data"
HOME_MOUNT_POINT="/home"
OLD_HOME_DIR_BACKUP="/home.old"

# --- Pre-flight Checks ---
# 1. Check if the storage disk is mounted at /data.
if ! findmnt -M "$DATA_MOUNT_POINT"; then
    echo "Error: The storage disk is not mounted at '$DATA_MOUNT_POINT'."
    echo "Please ensure the previous script has run successfully."
    exit 1
fi

# 2. Check if /home is already a mount point.
if findmnt -M "$HOME_MOUNT_POINT"; then
    echo "/home is already a mount point. Skipping."
    exit 0
fi

# --- Re-configure Mount Point ---

# 1. Find the device mounted at /data.
DEVICE=$(findmnt -n -o SOURCE --target "$DATA_MOUNT_POINT")
if [ -z "$DEVICE" ]; then
    echo "Error: Could not determine the device mounted at $DATA_MOUNT_POINT."
    exit 1
fi
echo "Found device: $DEVICE"

# 2. Unmount the device from /data.
echo "Unmounting $DEVICE from $DATA_MOUNT_POINT..."
umount "$DATA_MOUNT_POINT"

# 3. Backup the existing /home directory.
echo "Backing up existing /home to $OLD_HOME_DIR_BACKUP..."
# This also frees up the /home path for the new mount
mkdir -p "$OLD_HOME_DIR_BACKUP"
rsync -a /home/ "$OLD_HOME_DIR_BACKUP/"
rm -rf /home/* # Clean out the directory before mounting


# 4. Update /etc/fstab to change the mount point.
#    We use sed to find the line for /data and replace it with /home.
echo "Updating /etc/fstab to mount $DEVICE at $HOME_MOUNT_POINT..."
sed -i "s|$DATA_MOUNT_POINT|$HOME_MOUNT_POINT|" /etc/fstab

# 5. Mount the device at its new location.
echo "Mounting all filesystems defined in /etc/fstab..."
mount -a

# 6. Restore the original home directory contents.
echo "Restoring home directory contents..."
rsync -a "$OLD_HOME_DIR_BACKUP/" "$HOME_MOUNT_POINT/"

# 7. Verify the new mount.
if findmnt -M "$HOME_MOUNT_POINT"; then
    echo "✓ Successfully mounted $DEVICE at $HOME_MOUNT_POINT."
    # Clean up the backup
    echo "Removing backup directory ${OLD_HOME_DIR_BACKUP}..."
    rm -rf "${OLD_HOME_DIR_BACKUP}"
    # Also remove the now-unused /data directory
    rmdir "$DATA_MOUNT_POINT"
else
    echo "Error: Failed to mount $DEVICE at $HOME_MOUNT_POINT."
    echo "The old home directory is backed up at ${OLD_HOME_DIR_BACKUP}."
    exit 1
fi

echo "Configuration of /home on the persistent storage disk finished successfully."
