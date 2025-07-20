#!/bin/bash

# Bootstrap Startup Script
# This script's only job is to clone the deployment repository and then
# execute the main startup script from within the cloned repo.

set -e

# Logging setup
LOG_FILE="/var/log/startup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Bootstrap Script Started at $(date) ==="

echo "Installing git..."
apt-get update
apt-get install -y git

# Define repo URL and the destination directory for the clone
REPO_URL="https://github.com/nam20485/parsec-ws-deploy.git"
CLONE_DIR="/opt/parsec-ws-deploy"

echo "Cloning repository from $REPO_URL to $CLONE_DIR..."
git clone --depth 1 "$REPO_URL" "$CLONE_DIR"

MAIN_SCRIPT_PATH="$CLONE_DIR/scripts/main-startup.sh"

echo "Executing main startup script from the cloned repository..."
chmod +x "$MAIN_SCRIPT_PATH"
cd "$CLONE_DIR/scripts" && ./main-startup.sh

echo "=== Bootstrap Script Completed at $(date) ==="