#!/bin/bash

# Feature Script: NVIDIA GPU Driver Installation
# Renamed to 03-nvidia-drivers.sh
# Installs NVIDIA drivers and CUDA toolkit for Tesla T4 vWS GPU

set -e

echo "Starting NVIDIA GPU driver installation..."

# Check if NVIDIA GPU is present
if ! lspci | grep -i nvidia; then
    echo "No NVIDIA GPU detected. Skipping driver installation."
    exit 0
fi

echo "NVIDIA GPU detected:"
lspci | grep -i nvidia

# # Remove any existing NVIDIA drivers
# echo "Removing any existing NVIDIA drivers..."
# apt-get remove --purge -y nvidia-* || true
# apt-get autoremove -y || true

# # Add NVIDIA driver repository
# echo "Adding NVIDIA driver repository..."
# add-apt-repository ppa:graphics-drivers/ppa -y
# apt-get update

# # Install NVIDIA driver (version 470+ supports T4 vWS)
# echo "Installing NVIDIA driver..."
# apt-get install -y nvidia-driver-535

sudo apt install -y gcc-12
sudo apt install -y linux-headers-$(uname -r)
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 12
sudo update-alternatives --config gcc



# Install NVIDIA container toolkit (useful for Docker/containers)
echo "Installing NVIDIA container toolkit..."curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
  sudo apt-get install -y \
      nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

# Install CUDA toolkit
echo "Installing CUDA toolkit..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
rm cuda-keyring_1.1-1_all.deb
apt-get update
apt-get -y install cuda-toolkit-12-4

# Add CUDA to PATH
echo "Configuring CUDA environment..."
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> /etc/environment
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> /etc/environment

# Configure NVIDIA persistence daemon
echo "Configuring NVIDIA persistence daemon..."
systemctl enable nvidia-persistenced

# Set GPU performance mode
echo "Setting GPU performance mode..."
nvidia-smi -pm 1 || echo "Warning: Could not set persistence mode (GPU may not be ready yet)"

# Create a script to verify GPU after reboot
cat > /usr/local/bin/verify-gpu.sh << 'EOF'
#!/bin/bash
echo "=== GPU Verification ==="
nvidia-smi
echo "=== CUDA Verification ==="
nvcc --version
echo "=== GPU Verification Complete ==="
EOF

chmod +x /usr/local/bin/verify-gpu.sh

echo "✓ NVIDIA GPU driver installation completed successfully"
echo "Note: A reboot may be required for the driver to take full effect"
echo "Run 'nvidia-smi' after reboot to verify GPU functionality"
