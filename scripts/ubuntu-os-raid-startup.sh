#!/bin/bash
# ubuntu-os-raid-startup.sh
# Startup script to configure OS RAID after initial boot

# This script runs after the system is already booted from the first disk
# It will set up RAID 1 (mirror) for the OS for redundancy

# Log all actions
exec > >(tee -a /var/log/os-raid-setup.log) 2>&1
echo "Starting OS RAID setup at $(date)"

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y mdadm rsync

# Wait for second OS disk to be available
SECOND_DISK="/dev/disk/by-id/google-os-disk-2"
while [ ! -e "$SECOND_DISK" ]; do
    echo "Waiting for second OS disk to be available..."
    sleep 10
done

echo "Second OS disk found: $SECOND_DISK"

# Get the current root device
ROOT_DEVICE=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
echo "Current root device: $ROOT_DEVICE"

# Create partition table on second disk identical to first disk
echo "Creating partition table on second disk..."
sfdisk -d $ROOT_DEVICE | sfdisk $SECOND_DISK

# Wait for partitions to be created
sleep 5

# Set up RAID 1 for root filesystem
# Note: This is a complex process that typically requires a live CD/rescue mode
# For production, consider using LVM or creating the RAID during initial installation

echo "Setting up RAID 1 array for OS (this is experimental)..."

# Create degraded RAID array with just the second disk first
mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 missing ${SECOND_DISK}1

# Format the RAID device
mkfs.ext4 -F /dev/md0

# Create temporary mount point and copy root filesystem
mkdir -p /mnt/raid-root
mount /dev/md0 /mnt/raid-root

echo "Copying root filesystem to RAID array..."
rsync -avxHAX --progress / /mnt/raid-root/

# Update fstab on the new root
sed -i 's|'"$ROOT_DEVICE"'1|/dev/md0|g' /mnt/raid-root/etc/fstab

# Update initramfs configuration
echo "ARRAY /dev/md0 metadata=1.2 name=$(hostname):0" >> /mnt/raid-root/etc/mdadm/mdadm.conf

# Update GRUB configuration
chroot /mnt/raid-root update-initramfs -u
chroot /mnt/raid-root update-grub

# Install GRUB on second disk
chroot /mnt/raid-root grub-install $SECOND_DISK

umount /mnt/raid-root

echo "OS RAID setup preparation completed."
echo "IMPORTANT: Manual intervention required to complete OS RAID setup."
echo "This requires rebooting from rescue mode to add the original disk to the RAID array."

# Set up storage RAID (same as original script)
echo "Setting up storage RAID..."

# Wait for storage disks
STORAGE_DISK1="/dev/disk/by-id/google-storage-disk-1"
STORAGE_DISK2="/dev/disk/by-id/google-storage-disk-2"

while [ ! -e "$STORAGE_DISK1" ] || [ ! -e "$STORAGE_DISK2" ]; do
    echo "Waiting for storage disks to be available..."
    sleep 10
done

# Create RAID 0 array for storage
mdadm --create --verbose /dev/md1 --level=0 --raid-devices=2 $STORAGE_DISK1 $STORAGE_DISK2

# Wait for array to be ready
sleep 10

# Create filesystem on storage RAID
mkfs.ext4 -F /dev/md1

# Create mount point and mount
mkdir -p /mnt/storage
mount /dev/md1 /mnt/storage

# Add to fstab
echo "/dev/md1 /mnt/storage ext4 defaults 0 2" >> /etc/fstab

# Save RAID configurations
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

chmod 755 /mnt/storage

echo "Storage RAID setup completed."
echo "Setup completed at $(date)"
