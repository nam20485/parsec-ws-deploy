#!/bin/bash
# Feature Script: Docker Installation
# Renamed to 02-install-docker.sh
# Installs Docker and configures it for non-root usage

set -e

# Add Docker's official GPG key:
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# Install Docker packages
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Setup docker to run as non-root
groupadd docker || true
usermod -aG docker $USER || true

# Note: If running as root, $USER may not work. You may need to manually add users to the docker group after provisioning.

echo "✓ Docker installation and configuration completed successfully"
