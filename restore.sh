#!/bin/bash

# === Thorium Browser Auto Restore Script ===
# By: Captain Naksh x Gyandu Bhai 🔥

# === CONFIGURATION ===
GITNO_ENV_FILE="gitno.env"
ZIP_PASSWORD="${ZIP_PASSWORD:?ZIP_PASSWORD not set in Codespace secrets}"
MEGA_DOWNLOAD_DIR="/root"
CONTAINER_NAME="thorium"

echo "📦 Loading GITNO tag..."
if [[ -f "$GITNO_ENV_FILE" ]]; then
  source "$GITNO_ENV_FILE"
else
  echo "❌ gitno.env not found!"
  exit 1
fi

[[ -z "$GITNO" ]] && echo "❌ GITNO missing in env file!" && exit 1

# === STEP 1: Check for backup on MEGA ===
echo "🔍 Checking MEGA for backups tagged: $GITNO"
MEGA_FILE_NAME=$(mega-ls | grep "${GITNO}_browser_backup_" | sort | tail -n 1 || true)

if [[ -z "$MEGA_FILE_NAME" ]]; then
  echo "🆕 No backup found for $GITNO — looks like a fresh start!"
  echo "📁 Creating new /root/browser directory"
  mkdir -p /root/browser

  # 🧼 Remove old container if exists
  if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "🧨 Removing old container: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME"
  fi

  # 🚀 Launch new container
  echo "🆕 Starting fresh Thorium container..."
  docker run -d \
    --name "$CONTAINER_NAME" \
    -p 8085:3000 \
    -v /root/browser:/config \
    --shm-size=2g \
    --cpus="2" \
    rohan014233/thorium

  if [[ $? -eq 0 ]]; then
    echo "✅ New container launched at: http://localhost:8085"
  else
    echo "❌ Container launch failed. Check Docker logs."
  fi
  exit 0
fi

# === STEP 2: Restore from backup ===
echo "📥 Found backup: $MEGA_FILE_NAME. Downloading..."
mega-get "$MEGA_FILE_NAME" "$MEGA_DOWNLOAD_DIR"
[[ $? -ne 0 ]] && echo "❌ MEGA download failed." && exit 1

echo "🧼 Removing existing /root/browser (if any)..."
rm -rf /root/browser

echo "📂 Extracting backup..."
7z x -p"$ZIP_PASSWORD" "$MEGA_DOWNLOAD_DIR/$MEGA_FILE_NAME" -o/root >/dev/null
[[ $? -ne 0 ]] && echo "❌ Extraction failed!" && exit 1

echo "🔧 Fixing permissions..."
chown -R 911:911 /root/browser

# === STEP 3: Restart container ===
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
  echo "🧨 Removing old container: $CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME"
fi

echo "🚀 Launching Thorium container with restored data..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p 8085:3000 \
  -v /root/browser:/config \
  --shm-size=2g \
  --cpus="2" \
  rohan014233/thorium

if [[ $? -eq 0 ]]; then
  echo "✅ Restored container running at: http://localhost:8085"
else
  echo "❌ Container failed to launch. Something's sus."
fi
