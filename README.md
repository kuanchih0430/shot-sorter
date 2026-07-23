# shot-sorter

Automatically sorts macOS screenshots and screen recordings into dated folders with clean English filenames.

macOS saves captures with Chinese default names like
`截圖 2026-07-23 下午4.20.18.png` and dumps them all into one folder.
shot-sorter renames them to a sortable English convention and files them
away automatically, seconds after they are created.

```
Before                                      After
──────                                      ─────
截圖 2026-07-23 下午4.20.18.png          →  screenshots/2026-07/2026-07-23_16.20.18.png
螢幕錄影 2026-07-23 凌晨3.51.29.mov      →  recordings/2026-07/2026-07-23_03.51.29.mov
```

## How it works

1. `launchd` watches `~/screen_recording` via `WatchPaths` — a kernel-level
   folder watch managed by the OS. No daemon, no cron, no wake-ups when
   nothing happens.
2. When a new file lands, `launchd` spawns `organize.sh` once. The script
   waits for the file to finish writing, converts the Chinese 12-hour
   timestamp to 24-hour time, and moves it into a type + month folder.
3. The process exits in milliseconds. Nothing stays running.

```
~/screen_recording/
├── screenshots/
│   └── YYYY-MM/
│       └── YYYY-MM-DD_HH.MM.SS[_n].png
├── recordings/
│   └── YYYY-MM/
│       └── YYYY-MM-DD_HH.MM.SS[_n].mov
├── organize.log        # every move / skip, timestamped
└── organize.err.log    # stderr from launchd runs (normally empty)
```

Time-period conversion:

| Chinese | Meaning        | Hours   |
|---------|----------------|---------|
| 凌晨    | early morning  | 00–05   |
| 上午    | morning        | 06–11   |
| 中午    | noon           | 12      |
| 下午    | afternoon      | 13–17   |
| 晚上    | evening        | 18–23   |

Name collisions are resolved by auto-incrementing: `_2`, `_3`, ...

## Repository contents

| File | Purpose |
|------|---------|
| `organize.sh` | The organizer. Idempotent; safe to run manually any time. |
| `com.angus.organize.plist` | launchd agent definition (`WatchPaths` + 10s throttle). |
| `install.sh` | One-command setup: installs the script, loads the agent, points macOS screenshots at the watched folder. |

## Requirements

- macOS (tested on macOS with zsh/bash; the script targets the
  Traditional Chinese filename format)
- No dependencies — pure bash + built-in `launchd`

## Install

```bash
git clone https://github.com/kuanchih0430/shot-sorter.git
cd shot-sorter
bash install.sh
```

Then set the screen-recording save location manually (this one has no
public `defaults` key): press `⌘⇧5` → Options → Save to →
`~/screen_recording`.

Verify: take a screenshot, wait ~10 seconds, then

```bash
ls ~/screen_recording/screenshots
tail ~/screen_recording/organize.log
```

If your username is not `angus`, edit the absolute paths in
`com.angus.organize.plist` before installing (plists cannot expand `$HOME`).

## Configuration

| Change | Where | Reload needed? |
|--------|-------|----------------|
| Archive by day instead of month | `organize.sh`: change `month="${date:0:7}"` to `month="$date"` | No — script is re-read on every trigger |
| Watch a different folder | `SRC` in `organize.sh` **and** `WatchPaths` in the plist **and** `defaults write com.apple.screencapture location <path>` | Yes |
| Trigger frequency | `ThrottleInterval` in the plist (default 10s) | Yes |

Reload after plist changes:

```bash
launchctl unload ~/Library/LaunchAgents/com.angus.organize.plist
launchctl load   ~/Library/LaunchAgents/com.angus.organize.plist
```

## Troubleshooting

**Nothing happens after a screenshot.** First run the script manually —
`bash ~/scripts/organize.sh` — to separate script problems from trigger
problems. If the manual run works, force a launchd-context run:

```bash
launchctl kickstart -k gui/$(id -u)/com.angus.organize
launchctl list | grep organize     # middle number = last exit code
```

**Kickstart works but the watch never fires.** Your watched folder is
almost certainly under a TCC-protected path — see the warning below.

**Files skipped as "still writing".** Long recordings can take a while to
finalize; the script waits up to 60 seconds per file, then logs a skip.
The file is picked up on the next trigger.

All activity is logged to `organize.log`; launchd stderr goes to
`organize.err.log`.

## ⚠️ Do not watch Desktop, Documents, or Downloads

`launchd` `WatchPaths` **silently fails** on TCC-protected paths
(Desktop, Documents, Downloads): the script never fires, no error is
logged anywhere, and there is no privacy setting that can authorize
`launchd` itself. Keep the watched folder directly under `$HOME`
(e.g. `~/screen_recording`). If you want Desktop access for convenience,
use a symlink — it does not affect the watch:

```bash
ln -s ~/screen_recording ~/Desktop/screen_recording
```

Keeping the folder out of Desktop also keeps large `.mov` files away
from iCloud Desktop sync.

## Design notes

Why `launchd` + `WatchPaths` instead of the alternatives:

- **cron / polling** — wakes up constantly to find nothing; wasteful by design.
- **fswatch / watchdog daemon** — needs a resident process for a task that
  runs for milliseconds a few times a day.
- **watchman** — excellent for monorepos with tens of thousands of files;
  overkill for one folder.
- **launchd WatchPaths** — the OS-native mechanism: the kernel holds the
  watch, the OS manages the lifecycle, and the tool's complexity matches
  the problem's complexity.

Known `WatchPaths` limitations accepted in this design: it reports "the
folder changed", not which file (the script scans on each run — fine at
this scale), and events are coalesced (harmless here; the throttle
batches rapid captures anyway).

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.angus.organize.plist
rm ~/Library/LaunchAgents/com.angus.organize.plist
rm ~/scripts/organize.sh
defaults delete com.apple.screencapture location   # captures go back to Desktop
```

Already-organized files are left untouched.
