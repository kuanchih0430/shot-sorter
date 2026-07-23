#!/bin/bash
# install.sh — run from the repo root: bash install.sh
set -e

SCRIPT_DIR="$HOME/scripts"
AGENT_DIR="$HOME/Library/LaunchAgents"
LABEL="com.angus.organize"

# 1. Ensure the watched folder exists
mkdir -p "$HOME/screen_recording"

# 2. Install the script
mkdir -p "$SCRIPT_DIR"
cp organize.sh "$SCRIPT_DIR/organize.sh"
chmod +x "$SCRIPT_DIR/organize.sh"

# 3. Install and (re)load the launchd agent
mkdir -p "$AGENT_DIR"
launchctl unload "$AGENT_DIR/$LABEL.plist" 2>/dev/null || true
cp "$LABEL.plist" "$AGENT_DIR/$LABEL.plist"
launchctl load "$AGENT_DIR/$LABEL.plist"

# 4. Point macOS screenshots at the watched folder
defaults write com.apple.screencapture location "$HOME/screen_recording"

echo "Installed. Agent status:"
launchctl list | grep "$LABEL" || echo "(not listed — check organize.err.log)"
echo
echo "Test: take a screenshot, wait ~10s, then:"
echo "  ls ~/screen_recording/screenshots"
echo "  tail ~/screen_recording/organize.log"
