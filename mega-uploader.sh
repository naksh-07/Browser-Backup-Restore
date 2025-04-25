#!/bin/bash
# === MEGA Upload with Explicit Timestamp Extraction ===

set -euo pipefail

GITNO_ENV_FILE="gitno.env"
BACKUP_DIR="/root"

# 1) Load GITNO
if [[ -f $GITNO_ENV_FILE ]]; then
  source "$GITNO_ENV_FILE"
else
  echo "❌ $GITNO_ENV_FILE not found!"
  exit 1
fi
[[ -z ${GITNO:-} ]] && echo "❌ GITNO not set!" && exit 1

# 2) Pick latest local backup via parsing TIMESTAMP in filename
latest_ts=""
latest_file=""
for f in "$BACKUP_DIR/${GITNO}_browser_backup_"*.7z; do
  [[ ! -e $f ]] && continue
  fname=${f##*/}                                   # strip path
  ts=${fname#${GITNO}_browser_backup_}             # remove prefix
  ts=${ts%.7z}                                     # remove suffix
  # ts is like 20250425_014927
  if [[ -z $latest_ts || $ts > $latest_ts ]]; then
    latest_ts=$ts
    latest_file=$f
  fi
done

if [[ -z $latest_file ]]; then
  echo "❌ No local backup found for tag '$GITNO'."
  exit 1
fi
echo "🚀 Latest local backup: $latest_file (ts=$latest_ts)"

# 3) MEGA: find all backup filenames, extract their timestamps, delete the oldest
oldest_ts=""
oldest_name=""
while read -r name; do
  # name like c02_browser_backup_20250423_230000.7z
  ts=${name#${GITNO}_browser_backup_}
  ts=${ts%.7z}
  if [[ -z $oldest_ts || $ts < $oldest_ts ]]; then
    oldest_ts=$ts
    oldest_name=$name
  fi
done < <(mega-ls | grep "^${GITNO}_browser_backup_.*\.7z$" || true)

if [[ -n $oldest_name ]]; then
  echo "🧹 Deleting old MEGA backup: $oldest_name (ts=$oldest_ts)"
  mega-rm "$oldest_name"
fi

# 4) Upload the new one
echo "⏫ Uploading $latest_file to MEGA…"
mega-put "$latest_file" /

echo "✅ Uploaded: $(basename "$latest_file")"
