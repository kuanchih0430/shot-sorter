#!/bin/bash
# organize.sh — auto-organize macOS screenshots & screen recordings
# Triggered by launchd WatchPaths; safe to run manually too.
#
# Source folder: everything lands in $SRC with Chinese default names.
# Result:
#   $SRC/screenshots/YYYY-MM/YYYY-MM-DD_HH.MM.SS[_n].png
#   $SRC/recordings/YYYY-MM/YYYY-MM-DD_HH.MM.SS[_n].mov
# Conflicts get auto-incremented _2, _3, ...
# All actions logged to $SRC/organize.log

SRC="/Users/angus/screen_recording"
LOG="$SRC/organize.log"

cd "$SRC" || exit 1

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"
}

# Give macOS a moment to finish writing a just-saved recording.
sleep 3

# Convert Chinese time period + 12h clock to 24h "HH.MM.SS"
to_24h() {
    local period="$1" h="$2" m="$3" s="$4"
    h=$((10#$h))
    case "$period" in
        凌晨|上午) [ "$h" -eq 12 ] && h=0 ;;
        中午)      h=12 ;;
        下午|晚上) [ "$h" -ne 12 ] && h=$((h+12)) ;;
    esac
    printf "%02d.%02d.%02d" "$h" "$((10#$m))" "$((10#$s))"
}

# Move with auto-increment on name collision: name.ext, name_2.ext, name_3.ext ...
safe_move() {
    local src="$1" dir="$2" base="$3" ext="$4"
    local target="$dir/$base.$ext" n=2
    while [ -e "$target" ]; do
        target="$dir/${base}_${n}.$ext"
        n=$((n+1))
    done
    if mv "$src" "$target"; then
        log "MOVED: $src -> $target"
    else
        log "ERROR: failed to move $src"
    fi
}

process() {
    local prefix="$1" outdir="$2" ext="$3"
    local f date t month
    for f in "$prefix "*."$ext"; do
        [ -e "$f" ] || continue

        # Skip files modified in the last 5 seconds (may still be writing)
        local now mtime
        now=$(date +%s)
        mtime=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")
        if [ $((now - mtime)) -lt 5 ]; then
            log "SKIP (still writing?): $f"
            continue
        fi

        if [[ "$f" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})\ (凌晨|上午|中午|下午|晚上)([0-9]{1,2})\.([0-9]{2})\.([0-9]{2}) ]]; then
            date="${BASH_REMATCH[1]}"
            t=$(to_24h "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}")
            month="${date:0:7}"
            mkdir -p "$outdir/$month"
            safe_move "$f" "$outdir/$month" "${date}_${t}" "$ext"
        else
            log "SKIP (name not recognized): $f"
        fi
    done
}

process "截圖"     "screenshots" "png"
process "螢幕錄影" "recordings"  "mov"
