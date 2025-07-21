#!/bin/bash

# Renamed to 06-parsec-install.sh
#!/bin/bash

# Feature Script: Parsec Installation
# Downloads and installs the Parsec host application.

set -e

echo "Starting Parsec installation..."

# The Parsec download URL for Debian/Ubuntu-based systems
PARSEC_URL="https://builds.parsec.app/package/parsec-linux.deb"
PARSEC_DEB_FILE="/tmp/parsec-linux.deb"

echo "Downloading Parsec package from $PARSEC_URL..."
wget -O "$PARSEC_DEB_FILE" "$PARSEC_URL"

echo "Installing Parsec..."
# Use apt install to automatically handle dependencies
apt-get install -y "$PARSEC_DEB_FILE"

# Clean up the downloaded file
rm "$PARSEC_DEB_FILE"

echo "✓ Parsec installation completed successfully."
echo "IMPORTANT: You must now link this machine to your Parsec account."
echo "After connecting via SSH, run 'sudo parsec-host-config' to configure the host."