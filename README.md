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