#!/bin/bash

# Feature Script: System Update and Package Installation
# Updates the system and installs essential packages

set -e

echo "Starting system update and package installation..."

# Update package lists
echo "Updating package lists..."
apt-get update

# Upgrade system packages
echo "Upgrading system packages..."
apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    tree \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    linux-headers-$(uname -r) \
    dkms

# Install development tools
echo "Installing development tools..."
apt-get install -y \
    gcc \
    g++ \
    make \
    cmake \
    python3 \
    python3-pip \
    nodejs \
    npm

# Install multimedia and graphics libraries
echo "Installing multimedia and graphics libraries..."
apt-get install -y \
    ffmpeg \
    mesa-utils \
    vulkan-utils \
    libvulkan1 \
    libvulkan-dev

# Clean up package cache
echo "Cleaning up package cache..."
apt-get autoremove -y
apt-get autoclean

echo "✓ System update and package installation completed successfully"
