#!/bin/bash
# 08-nice-dcv-install.sh
# This script downloads, installs, and configures NICE DCV.

# Exit immediately if a command exits with a non-zero status.
set -e

# Variables
DCV_SERVER_URL="https://d1uj6qtbmh3dt5.cloudfront.net/2023.1/Servers/nice-dcv-2023.1-16388-ubuntu2204-x86_64.tgz"
DCV_SERVER_TGZ=$(basename "$DCV_SERVER_URL")
DCV_SERVER_DIR=$(basename "$DCV_SERVER_TGZ" .tgz)
GPG_KEY_URL="https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY"

# --- Installation ---

# 1. Download the NICE DCV server package
echo "Downloading NICE DCV server..."
wget "$DCV_SERVER_URL"

# 2. Download the NICE GPG key and import it
echo "Importing NICE GPG key..."
wget "$GPG_KEY_URL"
gpg --import NICE-GPG-KEY

# 3. Verify the download signature
echo "Verifying DCV server download..."
wget "$DCV_SERVER_URL.asc"
gpg --verify "${DCV_SERVER_TGZ}.asc" "$DCV_SERVER_TGZ"

# 4. Extract the archive
echo "Extracting DCV server..."
tar -xvzf "$DCV_SERVER_TGZ"

# 5. Install the DCV server
echo "Installing DCV server..."
cd "$DCV_SERVER_DIR"
sudo ./install-dcv --assumeyes

# --- Configuration ---

# 6. Enable and start the DCV server service
echo "Starting DCV server service..."
sudo systemctl enable dcvserver
sudo systemctl start dcvserver

# 7. Configure the firewall to allow DCV traffic
echo "Configuring firewall for DCV..."
sudo ufw allow 8443/tcp

# 8. Create a default session for the 'ubuntu' user
# This allows the user to connect without manually creating a session.
echo "Creating default DCV session..."
sudo dcv create-session --user ubuntu --name "default"

# --- Cleanup ---
echo "Cleaning up installation files..."
cd ..
rm -rf "$DCV_SERVER_DIR" "$DCV_SERVER_TGZ" "$DCV_SERVER_TGZ.asc" "NICE-GPG-KEY"

echo "NICE DCV installation and configuration complete."
