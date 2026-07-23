# shot-sorter

Automatically sorts macOS screenshots and screen recordings into dated folders with clean English filenames.

```
截圖 2026-07-23 下午4.20.18.png      →  screenshots/2026-07/2026-07-23_16.20.18.png
螢幕錄影 2026-07-23 凌晨3.51.29.mov  →  recordings/2026-07/2026-07-23_03.51.29.mov
```

Event-driven via `launchd` `WatchPaths` — no polling, no daemons. Pure bash, zero dependencies.

## Install

```bash
git clone https://github.com/kuanchih0430/shot-sorter.git
cd shot-sorter
bash install.sh
```

Then press `⌘⇧5` → Options → Save to → `~/screen_recording` (screen-recording location must be set manually).

If your username is not `angus`, edit the paths in `com.angus.organize.plist` first.

**Verify:** take a screenshot, wait ~10s:

```bash
ls ~/screen_recording/screenshots
tail ~/screen_recording/organize.log
```

## Configuration

| Change | Where | Reload? |
|--------|-------|---------|
| Archive by day instead of month | `organize.sh`: `month="${date:0:7}"` → `month="$date"` | No |
| Watch a different folder | `SRC` in `organize.sh` + `WatchPaths` in plist + `defaults write com.apple.screencapture location <path>` | Yes |

Reload = `launchctl unload` then `load` on the plist.

## ⚠️ Don't watch Desktop / Documents / Downloads

`WatchPaths` **silently fails** on these TCC-protected paths — no trigger, no error, and no way to authorize `launchd`. Keep the folder directly under `$HOME`; symlink it to Desktop if you want quick access:

```bash
ln -s ~/screen_recording ~/Desktop/screen_recording
```

## Troubleshooting

```bash
bash ~/scripts/organize.sh                        # script works? → trigger problem
launchctl kickstart -k gui/$(id -u)/com.angus.organize
launchctl list | grep organize                    # middle number = last exit code
tail ~/screen_recording/organize.log              # every move/skip is logged
```

Kickstart works but the watch never fires → see the warning above.

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.angus.organize.plist
rm ~/Library/LaunchAgents/com.angus.organize.plist ~/scripts/organize.sh
defaults delete com.apple.screencapture location
```
