#!/bin/bash

# Feature Script: Mount Storage and Scratch Disks
# Formats and mounts the attached persistent storage disk and the local scratch disk.

set -e

echo "Starting disk setup..."

# --- Mount Persistent Storage Disk ---

STORAGE_DISK_DEVICE=""
STORAGE_MOUNT_POINT="/data"

# Find the persistent disk (excluding the boot disk and NVMe disks)
BOOT_DISK_DEVICE_NAME=$(lsblk -no pkname "$(findmnt -n -o SOURCE /)")
for device in $(lsblk -dno NAME,TYPE | awk '$2 == "disk" {print "/dev/"$1}'); do
    if [[ "$device" != *"$BOOT_DISK_DEVICE_NAME"* && "$device" != *"/dev/nvme"* ]]; then
        STORAGE_DISK_DEVICE=$device
        break
    fi
done

if [ -z "$STORAGE_DISK_DEVICE" ]; then
    echo "No persistent storage disk found to mount. Skipping."
else
    echo "Found persistent storage disk: $STORAGE_DISK_DEVICE"

    # Check if the disk is already formatted
    if ! blkid -p -o value -s TYPE "$STORAGE_DISK_DEVICE" >/dev/null 2>&1; then
        echo "Formatting ${STORAGE_DISK_DEVICE} with ext4 filesystem..."
        mkfs.ext4 -F "$STORAGE_DISK_DEVICE"
    else
        echo "Disk ${STORAGE_DISK_DEVICE} already has a filesystem. Skipping format."
    fi

    # Create mount point and add to /etc/fstab for persistence
    mkdir -p "$STORAGE_MOUNT_POINT"
    DISK_UUID=$(blkid -s UUID -o value "$STORAGE_DISK_DEVICE")
    if ! grep -q "UUID=$DISK_UUID" /etc/fstab; then
        echo "Adding ${STORAGE_DISK_DEVICE} to /etc/fstab..."
        echo "UUID=$DISK_UUID $STORAGE_MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
    fi

    # Mount the disk
    mount -a
    chmod -R 777 "$STORAGE_MOUNT_POINT"
    echo "✓ Persistent storage disk mounted successfully at ${STORAGE_MOUNT_POINT}"
    df -h "$STORAGE_MOUNT_POINT"
fi


# --- Mount Local Scratch Disk ---

SCRATCH_DISK_DEVICE=""
SCRATCH_MOUNT_POINT="/mnt/scratch"

# Find the NVMe scratch disk
for device in $(lsblk -dno NAME,TYPE | awk '$2 == "disk" {print "/dev/"$1}'); do
    if [[ "$device" == *"/dev/nvme"* ]]; then
        SCRATCH_DISK_DEVICE=$device
        break
    fi
done

if [ -z "$SCRATCH_DISK_DEVICE" ]; then
    echo "No scratch disk found to mount. Skipping."
else
    echo "Found scratch disk: $SCRATCH_DISK_DEVICE"

    # Format the scratch disk (they are ephemeral and always need formatting on first use)
    echo "Formatting ${SCRATCH_DISK_DEVICE} with ext4 filesystem..."
    mkfs.ext4 -F "$SCRATCH_DISK_DEVICE"

    # Create mount point and mount the disk
    mkdir -p "$SCRATCH_MOUNT_POINT"
    mount "$SCRATCH_DISK_DEVICE" "$SCRATCH_MOUNT_POINT"
    
    # Note: We don't add the scratch disk to /etc/fstab because it's ephemeral.
    # A more robust solution for reboots involves a systemd mount unit.
    # For initial setup, this is sufficient.

    chmod -R 777 "$SCRATCH_MOUNT_POINT"
    echo "✓ Scratch disk mounted successfully at ${SCRATCH_MOUNT_POINT}"
    df -h "$SCRATCH_MOUNT_POINT"
fi

echo "Disk setup finished."