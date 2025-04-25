#!/bin/bash

# === Thorium Browser Auto Restore Script ===
# By: Captain Naksh  🛠️🧠

# === CONFIGURATION ===
GITNO_ENV_FILE="gitno.env"
ZIP_PASSWORD="${ZIP_PASSWORD:?ZIP_PASSWORD not set in Codespace secrets}"
MEGA_DOWNLOAD_DIR="/root"
CONTAINER_NAME="thorium"

# === STEP 1: Load GITNO Tag ===
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

# === STEP 2: Search Backup on MEGA ===
echo "🔍 Searching for latest backup on MEGA for tag: $GITNO"
MEGA_FILE_NAME=$(mega-ls | grep "${GITNO}_browser_backup_" | sort | tail -n 1)

if [[ -z "$MEGA_FILE_NAME" ]]; then
  echo "❌ No backup found on MEGA for $GITNO"
  exit 1
fi

echo "📥 Found backup: $MEGA_FILE_NAME. Downloading..."
mega-get "$MEGA_FILE_NAME" "$MEGA_DOWNLOAD_DIR"
if [[ $? -ne 0 ]]; then
  echo "❌ MEGA download failed."
  exit 1
fi

# === STEP 3: Clean any old browser directory ===
echo "🧼 Cleaning old /root/browser..."
rm -rf /root/browser

# === STEP 4: Extract directly into /root (not /root/browser) ===
echo "📂 Extracting backup into /root..."
7z x -p"$ZIP_PASSWORD" "$MEGA_DOWNLOAD_DIR/$MEGA_FILE_NAME" -o/root >/dev/null

if [[ $? -ne 0 ]]; then
  echo "❌ Extraction failed. Check password or file."
  exit 1
fi
echo "✅ Extraction successful."

# === STEP 5: Remove Old Container (if exists) ===
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
  echo "🧨 Removing old container: $CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME"
fi

# ✅ STEP : Fix ownership
echo "🔧 Setting ownership to UID:GID 911:911"
chown -R 911:911 /root/browser


# === STEP 6: Launch Restored Container ===
echo "🚀 Launching Thorium container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p 8085:3000 \
  -v /root/browser:/config \
  --shm-size=2g \
  --cpus="2" \
  rohan014233/thorium

if [[ $? -eq 0 ]]; then
  echo "✅ Thorium container running at http://localhost:8085"
else
  echo "❌ Failed to launch container. Check logs."
fi
