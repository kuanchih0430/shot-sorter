# Screenshot Organizer

Event-driven auto-organizer for macOS screenshots and screen recordings.
Uses launchd WatchPaths — zero polling, zero resident processes.

## How it works
- Watches `~/screen_recording` via launchd `WatchPaths`
- Renames Chinese default filenames (截圖/螢幕錄影) to English `YYYY-MM-DD_HH.MM.SS`
- Sorts into `screenshots/YYYY-MM/` and `recordings/YYYY-MM/`
- Auto-increments `_2`, `_3` on name collisions; logs to `organize.log`

## Install
1. Edit paths in `organize.sh` and the plist if your username differs
2. Run `bash install.sh`
3. `defaults write com.apple.screencapture location ~/screen_recording`

## Note
Do NOT place the watched folder under Desktop/Documents/Downloads —
launchd WatchPaths silently fails on TCC-protected paths.
