#!/bin/bash

# === browser.sh - Ultimate Backup Script ===
# Backs up the entire /root/browser directory as a single .7z file
# Author: Naveen Amrawanshi💥

# === CONFIGURATION ===
CONTAINER_NAME="thorium"
MOUNT_PATH="/root/browser"
BACKUP_DIR="/root"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 1) Load credentials
if [[ -f mega.env ]]; then
  # echo "Loading MEGA creds..."
  source mega.env
else
  echo "❌ mega.env not found! Run gen_mega_env.sh first."
  exit 1
fi


# === Load GITNO from gitno.env ===
GITNO_ENV_FILE="gitno.env"
echo "📦 Loading GITNO tag..."

if [[ -f "$GITNO_ENV_FILE" ]]; then
  source "$GITNO_ENV_FILE"
else
  echo "❌ gitno.env not found at $GITNO_ENV_FILE"
  exit 1
fi

if [[ -z "$GITNO" ]]; then
  echo "❌ GITNO not set in gitno.env"
  exit 1
fi

ZIP_FILE="$BACKUP_DIR/${GITNO}_browser_backup_${TIMESTAMP}.7z"
echo "📁 Mount path: $MOUNT_PATH"
echo "📦 Backup target: $ZIP_FILE"

mkdir -p "$BACKUP_DIR"

# ✅ STEP 1: Check container is running
if ! docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
  echo "❌ Container '$CONTAINER_NAME' is not running. Aborting."
  exit 1
fi

# ✅ STEP 2: Gracefully kill browser inside container
echo "🧘 Gracefully stopping Thorium browser..."
docker exec "$CONTAINER_NAME" pkill -SIGTERM thorium || echo "⚠️ Thorium may not be running"
sleep 3

# ✅ STEP 3: Stop container for clean backup
echo "🧊 Stopping container..."
docker stop "$CONTAINER_NAME"

# ✅ STEP 4: Fix ownership
echo "🔧 Setting ownership to UID:GID 911:911"
chown -R 911:911 "$MOUNT_PATH/.config/thorium" 2>/dev/null || true

# ✅ STEP 5: Clean volatile browser cache
echo "🧹 Cleaning volatile cache"
rm -rf "$MOUNT_PATH/.config/thorium/Default/Cache"
rm -rf "$MOUNT_PATH/.config/thorium/Default/Code Cache"
rm -rf "$MOUNT_PATH/.config/thorium/ShaderCache"
rm -rf "$MOUNT_PATH/.config/thorium/GPUCache"
rm -rf "$MOUNT_PATH/.config/thorium/Singleton*"

# ✅ STEP 6: Compress the full browser folder into encrypted 7z
echo "📦 Creating encrypted 7z archive..."
cd /root
7z a -t7z -mhe=on -p"$ZIP_PASSWORD" "$ZIP_FILE" browser

if [[ $? -ne 0 ]]; then
  echo "❌ Backup compression failed!"
  docker start "$CONTAINER_NAME"
  exit 1
fi

# ✅ STEP 7: Restart container
echo "🔁 Restarting container..."
docker start "$CONTAINER_NAME"

echo "✅ Backup complete: $ZIP_FILE"
