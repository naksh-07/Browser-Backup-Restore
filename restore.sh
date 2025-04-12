#!/bin/bash

# === ADVANCED THORIUM TARBALL RESTORE SCRIPT ===
# Author: ChatGPT & arkashshs 🧠🔥
# Purpose: Restore Thorium browser state from a tarball and relaunch the container cleanly

# === CONFIG ===
BACKUP_TARBALL="browser_backup_20250408_172136.tar.gz"  # Update this or autodetect latest
RESTORE_DIR="/root/browser"
CONTAINER_NAME="thorium"
IMAGE_NAME="zydou/thorium:latest"
PORT=8085

echo "📦 Backup tarball: $BACKUP_TARBALL"
echo "📁 Target restore directory: $RESTORE_DIR"

# === STEP 1: Sanity check for tarball ===
if [[ ! -f "$BACKUP_TARBALL" ]]; then
  echo "❌ Backup tarball not found: $BACKUP_TARBALL"
  exit 1
fi

# === STEP 2: Stop and remove existing container if it exists ===
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
  echo "🧊 Stopping and removing container '$CONTAINER_NAME'..."
  docker stop "$CONTAINER_NAME" >/dev/null || true
  docker rm "$CONTAINER_NAME" >/dev/null || true
fi

# === STEP 3: Prepare restore directory ===
echo "📁 Preparing restore directory..."
mkdir -p "$RESTORE_DIR"
rm -rf "$RESTORE_DIR"/*

# === STEP 4: Extract the tarball ===
echo "📦 Extracting backup into $RESTORE_DIR..."
tar -xzf "$BACKUP_TARBALL" -C "$RESTORE_DIR"
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to extract tarball."
  exit 1
fi

# === STEP 5: Fix ownership for container user (911:911) ===
echo "🔒 Setting proper permissions..."
chown -R 911:911 "$RESTORE_DIR"

# === STEP 6: Launch Thorium container with restored data ===
echo "🚀 Launching container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "$PORT:3000" \
  -v "$RESTORE_DIR:/config" \
  -e PUID=911 \
  -e PGID=911 \
  --shm-size=2g \
  --cpus="2" \
  "$IMAGE_NAME"

if [[ $? -ne 0 ]]; then
  echo "❌ Failed to start container!"
  exit 1
fi

echo "✅ Restore complete! Thorium is running at: http://localhost:$PORT"
