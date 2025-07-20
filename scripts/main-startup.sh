#!/bin/bash

# Main startup script for Ubuntu server
# This script automatically discovers and runs all feature scripts in the features directory

set -e  # Exit on any error

# Logging setup
LOG_FILE="/var/log/startup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Main Startup Script Started at $(date) ==="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURES_DIR="$SCRIPT_DIR/features"

echo "Script directory: $SCRIPT_DIR"
echo "Features directory: $FEATURES_DIR"

# Check if features directory exists
if [[ ! -d "$FEATURES_DIR" ]]; then
    echo "ERROR: Features directory not found at $FEATURES_DIR"
    echo "Creating features directory..."
    mkdir -p "$FEATURES_DIR"
    echo "Features directory created, but no feature scripts found to execute."
    exit 0
fi

# Find and execute all feature scripts
echo "Looking for feature scripts in $FEATURES_DIR..."

# Get all .sh files in features directory and sort them
FEATURE_SCRIPTS=($(find "$FEATURES_DIR" -name "*.sh" -type f | sort))

if [[ ${#FEATURE_SCRIPTS[@]} -eq 0 ]]; then
    echo "No feature scripts found in $FEATURES_DIR"
    exit 0
fi

echo "Found ${#FEATURE_SCRIPTS[@]} feature script(s):"
for script in "${FEATURE_SCRIPTS[@]}"; do
    echo "  - $(basename "$script")"
done

# Execute each feature script
for script in "${FEATURE_SCRIPTS[@]}"; do
    script_name=$(basename "$script")
    echo ""
    echo "=== Executing feature script: $script_name ==="
    echo "Started at: $(date)"
    
    # Make script executable
    chmod +x "$script"
    
    # Execute the script
    if "$script"; then
        echo "✓ $script_name completed successfully"
    else
        echo "✗ $script_name failed with exit code $?"
        echo "Continuing with next script..."
    fi
    
    echo "Finished at: $(date)"
done

echo ""
echo "=== Main Startup Script Completed at $(date) ==="
echo "Check $LOG_FILE for full execution log"
