#!/bin/bash
# ubuntu-startup.sh
# Startup script for Ubuntu server to configure RAID array

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages for RAID management
apt-get install -y mdadm

# Wait for disks to be available
sleep 30

# Identify the attached persistent disks (excluding boot disk)
DISK1="/dev/disk/by-id/google-storage-disk-1"
DISK2="/dev/disk/by-id/google-storage-disk-2"

# Wait for disks to be ready
while [ ! -e "$DISK1" ] || [ ! -e "$DISK2" ]; do
    echo "Waiting for storage disks to be available..."
    sleep 10
done

# Create RAID 0 array for maximum performance
echo "Creating RAID 0 array with storage disks..."
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 $DISK1 $DISK2

# Wait for array to be ready
sleep 10

# Create filesystem on the RAID array
echo "Creating ext4 filesystem on RAID array..."
mkfs.ext4 -F /dev/md0

# Create mount point
mkdir -p /mnt/storage

# Mount the RAID array
mount /dev/md0 /mnt/storage

# Add to fstab for persistent mounting
echo "/dev/md0 /mnt/storage ext4 defaults 0 2" >> /etc/fstab

# Save RAID configuration
mdadm --detail --scan >> /etc/mdadm/mdadm.conf

# Update initramfs to include RAID configuration
update-initramfs -u

# Set permissions
chmod 755 /mnt/storage

# Install GPU drivers (optional - uncomment if needed)
# apt-get install -y nvidia-driver-470

echo "RAID setup completed. Storage available at /mnt/storage"
echo "RAID status:"
cat /proc/mdstat

# Log completion
echo "Ubuntu startup script completed at $(date)" >> /var/log/startup-script.log
