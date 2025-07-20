#!/bin/bash

# Feature Script: Mount Data Disk
# Formats and mounts the single attached data disk.

set -e

echo "Starting data disk setup..."

DATA_DISK_DEVICE=""
MOUNT_POINT="/data" # A common mount point for data disks

# Dynamically find the data disk (all 'disk' type devices except the one hosting the root partition)
BOOT_DISK_NAME=$(lsblk -no pkname "$(findmnt -n -o SOURCE /)")
DATA_DISKS=($(lsblk -dno NAME,TYPE | awk -v boot_disk="$BOOT_DISK_NAME" '$2 == "disk" && $1 != boot_disk {print "/dev/"$1}'))

if [[ ${#DATA_DISKS[@]} -eq 1 ]]; then
    DATA_DISK_DEVICE="${DATA_DISKS[0]}"
    echo "Found data disk: $DATA_DISK_DEVICE"
elif [[ ${#DATA_DISKS[@]} -gt 1 ]]; then
    echo "ERROR: Found multiple non-boot disks. This script is for a single data disk."
    exit 1
else
    echo "No data disks found to mount. Skipping."
    exit 0
fi

# Check if the disk is already formatted with a filesystem
if ! blkid -p -o value -s TYPE "$DATA_DISK_DEVICE" >/dev/null 2>&1; then
    echo "Formatting ${DATA_DISK_DEVICE} with ext4 filesystem..."
    mkfs.ext4 -F "$DATA_DISK_DEVICE"
else
    echo "Disk ${DATA_DISK_DEVICE} already has a filesystem. Skipping format."
fi

# Create mount point and mount the disk
mkdir -p "$MOUNT_POINT"
mount "$DATA_DISK_DEVICE" "$MOUNT_POINT"

# Add to /etc/fstab for persistence across reboots
if ! grep -q "${DATA_DISK_DEVICE}" /etc/fstab; then
    echo "Adding ${DATA_DISK_DEVICE} to /etc/fstab..."
    echo "${DATA_DISK_DEVICE} ${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab
fi

chmod -R 777 "$MOUNT_POINT"
echo "✓ Data disk mounted successfully at ${MOUNT_POINT}"
df -h "$MOUNT_POINT"
