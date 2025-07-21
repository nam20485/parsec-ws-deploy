#!/bin/bash

# Feature Script: Mount Storage and Scratch Disks using LVM
# Initializes LVM on two secondary disks, creates a volume group,
# and then creates and mounts logical volumes for storage and scratch space.

set -e

echo "Starting LVM disk setup..."

# --- LVM Configuration ---
VG_NAME="parsec_vg"
LV_STORAGE_NAME="storage_lv"
LV_STORAGE_SIZE="75%VG" # Use 75% of the VG for storage
LV_SCRATCH_NAME="scratch_lv"
LV_SCRATCH_SIZE="100%FREE" # Use the rest for scratch
STORAGE_MOUNT_POINT="/data"
SCRATCH_MOUNT_POINT="/mnt/scratch"

# --- Find Secondary Disks ---
# Find two disks that are not the boot disk.
BOOT_DISK_DEVICE_NAME=$(lsblk -no pkname "$(findmnt -n -o SOURCE /)")
SECONDARY_DISKS=()
for device in $(lsblk -dno NAME,TYPE | awk '$2 == "disk" {print "/dev/"$1}'); do
    if [[ "$device" != *"$BOOT_DISK_DEVICE_NAME"* ]]; then
        SECONDARY_DISKS+=("$device")
    fi
done

if [ "${#SECONDARY_DISKS[@]}" -lt 2 ]; then
    echo "Error: At least two secondary disks are required for this LVM setup."
    exit 1
fi

DISK1=${SECONDARY_DISKS[0]}
DISK2=${SECONDARY_DISKS[1]}

echo "Found secondary disks: $DISK1 and $DISK2"

# --- Initialize LVM ---

# 1. Create Physical Volumes (PVs)
echo "Creating Physical Volumes..."
pvcreate -f "$DISK1" "$DISK2"

# 2. Create Volume Group (VG)
echo "Creating Volume Group: $VG_NAME"
vgcreate "$VG_NAME" "$DISK1" "$DISK2"

# 3. Create Logical Volumes (LVs)
echo "Creating Logical Volumes..."
lvcreate -n "$LV_STORAGE_NAME" -l "$LV_STORAGE_SIZE" "$VG_NAME"
lvcreate -n "$LV_SCRATCH_NAME" -l "$LV_SCRATCH_SIZE" "$VG_NAME"

LV_STORAGE_DEVICE="/dev/$VG_NAME/$LV_STORAGE_NAME"
LV_SCRATCH_DEVICE="/dev/$VG_NAME/$LV_SCRATCH_NAME"

# --- Format and Mount Logical Volumes ---

# Format LVs with ext4
echo "Formatting logical volumes..."
mkfs.ext4 "$LV_STORAGE_DEVICE"
mkfs.ext4 "$LV_SCRATCH_DEVICE"

# --- Mount Storage LV ---
echo "Mounting storage logical volume..."
mkdir -p "$STORAGE_MOUNT_POINT"
# Add to /etc/fstab for persistence
if ! grep -q "$LV_STORAGE_DEVICE" /etc/fstab; then
    echo "Adding ${LV_STORAGE_DEVICE} to /etc/fstab..."
    echo "$LV_STORAGE_DEVICE $STORAGE_MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
fi
mount -a
chmod -R 777 "$STORAGE_MOUNT_POINT"
echo "✓ Storage LV mounted successfully at ${STORAGE_MOUNT_POINT}"
df -h "$STORAGE_MOUNT_POINT"


# --- Mount Scratch LV ---
echo "Mounting scratch logical volume..."
mkdir -p "$SCRATCH_MOUNT_POINT"
mount "$LV_SCRATCH_DEVICE" "$SCRATCH_MOUNT_POINT"
chmod -R 777 "$SCRATCH_MOUNT_POINT"
echo "✓ Scratch LV mounted successfully at ${SCRATCH_MOUNT_POINT}"
df -h "$SCRATCH_MOUNT_POINT"


echo "LVM disk setup finished."
