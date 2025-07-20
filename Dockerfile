# Dockerfile for functionally testing the GCE startup scripts

# Use the same base OS as specified in your ubuntu-server.tf
FROM ubuntu:25.04

# Set non-interactive frontend to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential dependencies that our scripts rely on.
# These are typically pre-installed on a GCE image, but not in a base Docker image.
# 'lspci' is needed for the NVIDIA script to check for a GPU.
# 'gcloud' is needed for the asset download script.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    sudo \
    procps \
    software-properties-common \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy the entire scripts directory into a path that mirrors the bootstrap script's logic
COPY ./scripts /opt/parsec-ws-deploy/scripts

# Set the working directory to where the scripts are located
WORKDIR /opt/parsec-ws-deploy/scripts

# Make the main startup script executable
RUN chmod +x main-startup.sh
RUN chmod +x bootstrap-startup.sh

# Define the command to run when the container starts. This simulates the final
# step of your bootstrap-startup.sh script.
CMD ["./bootstrap-startup.sh"]