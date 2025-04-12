#!/bin/bash

# === ADVANCED DOCKER TAR VOLUME BACKUP SCRIPT ===
# Author: ChatGPT & arkashshs 🧠🔥
# Purpose: Cleanly back up the mounted Thorium browser directory into a compressed tarball

# === CONFIG ===
CONTAINER_NAME="thorium"
MOUNT_PATH="/root/browser"
BACKUP_DIR="/root/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/browser_backup_$TIMESTAMP.tar.gz"

echo "🌐 Mount path: $MOUNT_PATH"
echo "📦 Backup target: $BACKUP_FILE"

# === STEP 1: Ensure backup directory exists ===
mkdir -p "$BACKUP_DIR"

# === STEP 2: Check container is running ===
echo "🚀 Checking container '$CONTAINER_NAME'..."
if ! docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
  echo "❌ Container '$CONTAINER_NAME' is not running. Aborting."
  exit 1
fi

# === STEP 3: Gracefully stop Thorium browser process ===
echo "🔒 Sending SIGTERM to browser process inside container..."
docker exec "$CONTAINER_NAME" pkill -SIGTERM thorium || echo "⚠️ Thorium might not be running"
sleep 3

# === STEP 4: Stop the container for data consistency ===
echo "🧊 Stopping container '$CONTAINER_NAME'..."
docker stop "$CONTAINER_NAME"

# === STEP 5: Fix permissions to allow cache cleanup ===
echo "🔧 Fixing permissions for mounted files..."
chown -R 911:911 "$MOUNT_PATH/.config/thorium" 2>/dev/null || true

# === STEP 6: Clean volatile Chromium cache from mount ===
echo "🧹 Cleaning volatile cache data..."
rm -rf "$MOUNT_PATH/.config/thorium/Default/Cache"
rm -rf "$MOUNT_PATH/.config/thorium/Default/Code Cache"
rm -rf "$MOUNT_PATH/.config/thorium/ShaderCache"
rm -rf "$MOUNT_PATH/.config/thorium/GPUCache"
rm -rf "$MOUNT_PATH/.config/thorium/Singleton*"
echo "✅ Cache cleaned."

# === STEP 7: Create compressed tarball of the mount directory ===
echo "📦 Creating compressed backup..."
tar -czf "$BACKUP_FILE" -C "$MOUNT_PATH" .
echo "✅ Backup created at: $BACKUP_FILE"

# === STEP 8: Restart the container ===
echo "▶️ Restarting container..."
docker start "$CONTAINER_NAME"

# === DONE ===
echo "✅ Tarball backup complete and container restarted!"
