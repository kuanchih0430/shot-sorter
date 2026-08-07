# rclone Cheatsheet

Remote in this project is `gdrive:`.

## ⚠️ copy vs sync vs move

| Command | **Deletes on destination** |
|---------|:--------------------------:|
| `copy`  | 本地刪了 遠端保留 |
| `sync`  | 完全同步 |
| `move`  | 本地搬去遠端 |

This project uses `copy`. **Always `--dry-run` a `sync` first.**

## Everyday

```bash
rclone copy SRC DST -P           # append-only transfer, with progress
rclone ls gdrive:path            # files + sizes
rclone lsd gdrive:path           # directories only
rclone size gdrive:path          # total count and bytes
rclone about gdrive:             # quota used / free
rclone check SRC DST --one-way   # verify everything local exists on remote
```

Server-side rename — no bandwidth used:

```bash
rclone move gdrive:old gdrive:new
```

## Flags worth knowing

| Flag | Effect |
|------|--------|
| `-P` | Progress, speed, ETA |
| `-n` / `--dry-run` | Show what would happen, change nothing |
| `-vv` | Debug output |
| `--transfers N` | Parallel transfers (default 4) |
| `--bwlimit 5M` | Cap bandwidth |
| `--exclude "*.tmp"` | Skip matching paths |

## Delete

```bash
rclone delete gdrive:path --dry-run   # check first
rclone delete gdrive:path             # files only
rclone purge gdrive:path              # path and everything under it
```

## Google Drive gotchas

- Own `client_id` is required — the shared one is retired.
- OAuth app left in "Testing" status → refresh token dies after 7 days. Publish it.
- `~/.config/rclone/rclone.conf` holds your secret and tokens. Never commit it.
- Token expired: `rclone config reconnect gdrive:`

## This project

```bash
IDLE_MIN=0 bash ~/projects/shot-sorter/backup.sh   # manual run, skip idle check
cat ~/screen_recording/backup_record.csv           # what has been backed up
tail ~/screen_recording/backup.log
```