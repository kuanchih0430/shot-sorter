#!/bin/bash
# backup.sh — append-only nightly backup of class/ and group_meeting/ to Google Drive.
# Runs hourly 01:00–06:00 via launchd; exits unless the Mac has been idle 30+ min.

SRC="$HOME/screen_recording"
REMOTE="gdrive:quant_class_backup"
DIRS=("class" "group_meeting")
IDLE_MIN="${IDLE_MIN:-30}"

RECORD="$SRC/backup_record.csv"
LOG="$SRC/backup.log"
LOCK="/tmp/shot-sorter-backup.lock"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"   # launchd has a minimal PATH

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK"' EXIT

idle=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
[ "${idle:-0}" -lt $((IDLE_MIN * 60)) ] && exit 0

[ -f "$RECORD" ] || echo "file,size_mb,backed_up_at" > "$RECORD"

for d in "${DIRS[@]}"; do
    [ -d "$SRC/$d" ] || continue

    if ! rclone copy "$SRC/$d" "$REMOTE/$d" --log-file "$LOG" --log-level INFO; then
        log "ERROR: rclone failed on $d — record not updated"
        continue
    fi

    while IFS= read -r f; do
        rel="${f#"$SRC"/}"
        grep -qF "$rel," "$RECORD" && continue
        size=$(du -m "$f" | cut -f1)
        echo "$rel,$size,$(date '+%Y-%m-%d %H:%M')" >> "$RECORD"
        log "BACKED UP: $rel (${size}MB)"
    done < <(find "$SRC/$d" -type f ! -name '.DS_Store')
done