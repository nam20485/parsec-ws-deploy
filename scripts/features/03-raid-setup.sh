#!/bin/bash

# Feature Script: RAID Setup
# Sets up RAID 0 array using the two attached persistent disks

set -e

echo "Starting RAID setup..."

# Install mdadm for software RAID
echo "Installing mdadm..."
apt-get update
apt-get install -y mdadm

# Identify the attached disks (excluding boot disk)
echo "Identifying available disks..."
lsblk

# The attached disks should be /dev/sdb and /dev/sdc (assuming /dev/sda is boot disk)
DISK1="/dev/sdb"
DISK2="/dev/sdc"

# Verify disks exist
if [[ ! -b "$DISK1" ]]; then
    echo "ERROR: Disk $DISK1 not found"
    lsblk
    exit 1
fi

if [[ ! -b "$DISK2" ]]; then
    echo "ERROR: Disk $DISK2 not found" 
    lsblk
    exit 1
fi

echo "Found disks for RAID:"
echo "  - $DISK1: $(lsblk -dno SIZE $DISK1)"
echo "  - $DISK2: $(lsblk -dno SIZE $DISK2)"

# Check if RAID array already exists
if [[ -b "/dev/md0" ]]; then
    echo "RAID array /dev/md0 already exists. Skipping RAID creation."
    mdadm --detail /dev/md0
    exit 0
fi

# Create RAID 0 array
echo "Creating RAID 0 array..."
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 $DISK1 $DISK2

# Wait for array to be ready
echo "Waiting for RAID array to be ready..."
sleep 5

# Verify RAID array
echo "Verifying RAID array..."
mdadm --detail /dev/md0

# Create filesystem on RAID array
echo "Creating ext4 filesystem on RAID array..."
mkfs.ext4 -F /dev/md0

# Create mount point
echo "Creating mount point..."
mkdir -p /mnt/raid

# Mount the RAID array
echo "Mounting RAID array..."
mount /dev/md0 /mnt/raid

# Add to /etc/fstab for persistent mounting
echo "Adding RAID array to /etc/fstab..."
echo "/dev/md0 /mnt/raid ext4 defaults 0 2" >> /etc/fstab

# Save RAID configuration
echo "Saving RAID configuration..."
mdadm --detail --scan >> /etc/mdadm/mdadm.conf

# Update initramfs
echo "Updating initramfs..."
update-initramfs -u

# Set permissions
echo "Setting permissions..."
chmod 755 /mnt/raid
chown root:root /mnt/raid

# Display final status
echo "RAID setup completed!"
echo ""
echo "=== RAID Array Status ==="
mdadm --detail /dev/md0
echo ""
echo "=== Filesystem Info ==="
df -h /mnt/raid
echo ""
echo "=== Mount Point ==="
echo "RAID array mounted at: /mnt/raid"

echo "✓ RAID setup completed successfully"
