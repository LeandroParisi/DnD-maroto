# DnD-maroto

## Backup

1. Go to Foundry VTT server: https://dnd-maroto.fly.dev/setup
2. Create backup manually
3. Login to fly.io via SSH:
   ```bash
   flyctl ssh console -a dnd-maroto
   ```
4. List all files inside backup folder
   ```bash
   find "/home/foundry/data/Backups" -type f
   ```
5. Copy the file full paths from the terminal
6. Add the full path to the array on the backup.sh script
7. Run the backup script:
   ```bash
   bash scripts/backup.sh
   ```

The script will download backups to `.backup/dnd-maroto_<date>/` preserving the directory structure.

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