#!/bin/bash

# Feature Script: Download and Unpack Assets
# Downloads a specified archive from a GCS bucket and unpacks it.

set -e

echo "Starting asset download from GCS..."

# --- USER CONFIGURATION ---
# Change these variables to match your GCS bucket and file name.
GCS_BUCKET_NAME="parsec-ws-deploy-assets" # <-- CHANGE THIS to your bucket name
ARCHIVE_FILE_NAME="archive.zip"           # <-- CHANGE THIS to your archive file name
DESTINATION_DIR="/opt/assets"             # Where to unpack the assets
# --- END CONFIGURATION ---

GCS_SOURCE_PATH="gs://${GCS_BUCKET_NAME}/${ARCHIVE_FILE_NAME}"
LOCAL_ARCHIVE_PATH="/tmp/${ARCHIVE_FILE_NAME}"

echo "Downloading ${GCS_SOURCE_PATH} to ${LOCAL_ARCHIVE_PATH}..."
# The VM's service account automatically has read access to GCS buckets in the same project.
gcloud storage cp "$GCS_SOURCE_PATH" "$LOCAL_ARCHIVE_PATH"

echo "Unpacking archive to ${DESTINATION_DIR}..."
mkdir -p "$DESTINATION_DIR"
# The 'unzip' package was installed by 01-system-update.sh
unzip -o "$LOCAL_ARCHIVE_PATH" -d "$DESTINATION_DIR"

echo "Cleaning up downloaded archive..."
rm "$LOCAL_ARCHIVE_PATH"

echo "✓ Assets downloaded and unpacked successfully to ${DESTINATION_DIR}"