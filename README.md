# DnD-maroto

## Backup

1. Go to Foundry VTT server: https://dnd-maroto.fly.dev/setup
2. Create backup manually
3. Run the backup script with a date parameter:
   ```bash
   bash scripts/backup.sh 2026-01-18
   ```
   Date format: `YYYY-MM-DD` (e.g., `2026-01-18`)

   To preview files without downloading, use `--dry-run`:
   ```bash
   bash scripts/backup.sh 2026-01-18 --dry-run
   ```

The script will automatically fetch all files from `/home/foundry/data/` on the remote server and download them, backing up all folders (Backups, Config, Data, etc.).

The script will download files to `.backup/<date>/` preserving the directory structure (e.g., `.backup/2026-01-18/Backups/...`, `.backup/2026-01-18/Config/...`).

## Upload maps

Upload all maps from `.maps/` folder to the Foundry server.

**Basic usage:**
```bash
bash scripts/upload-maps.sh
```

This will upload all files from `.maps/` to `/home/foundry/data/Data/assets/Maps` on the remote server, preserving the folder structure.

**Options:**
- `--dry-run`: Preview files without uploading
  ```bash
  bash scripts/upload-maps.sh --dry-run
  ```

- `--number-of-files=N`: Upload only the first N files (useful for testing)
  ```bash
  bash scripts/upload-maps.sh --number-of-files=10
  ```

**Examples:**
```bash
# Upload all maps
bash scripts/upload-maps.sh

# Preview what would be uploaded
bash scripts/upload-maps.sh --dry-run

# Upload only first 5 files (for testing)
bash scripts/upload-maps.sh --number-of-files=5

# Combine options
bash scripts/upload-maps.sh --number-of-files=20 --dry-run
```

The script will automatically create the necessary directory structure on the remote server and show progress for each file uploaded.

## Extend volume
1. List volumes
```bash
   fly volumes list -a dnd-maroto
```
2. GEt volume id to expand
3. Run
```bash
   fly volumes extend vol_remjy95yxw7y5kd4 -a dnd-maroto -s 7
```

## Scripts
1. Log in to machine with ssh
   flyctl ssh console -a dnd-maroto
   