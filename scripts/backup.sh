#!/bin/bash

# Ensure script is run with bash (not sh)
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Function to validate date format (YYYY-MM-DD)
validate_date() {
    local date_str="$1"
    
    # Check format matches YYYY-MM-DD
    if [[ ! "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 1
    fi
    
    # Extract year, month, day
    local year="${date_str%%-*}"
    local month_day="${date_str#*-}"
    local month="${month_day%-*}"
    local day="${month_day##*-}"
    
    # Check if date can be parsed and matches input (prevents normalization of invalid dates)
    local parsed_date
    parsed_date=$(date -d "$date_str" +"%Y-%m-%d" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ "$parsed_date" != "$date_str" ]; then
        return 1
    fi
    
    return 0
}

# Parse command line arguments
DRY_RUN=false
DATE_PARAM=""

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        *)
            if [ -z "$DATE_PARAM" ]; then
                DATE_PARAM="$arg"
            fi
            ;;
    esac
done

# Check if date parameter was provided
if [ -z "$DATE_PARAM" ]; then
    echo "Usage: $0 <date> [--dry-run]"
    echo "  Date format: YYYY-MM-DD (e.g., 2026-01-18)"
    echo "  --dry-run:   List files without downloading"
    exit 1
fi

# Validate the date parameter
if ! validate_date "$DATE_PARAM"; then
    echo "✗ Invalid date format: $DATE_PARAM"
    echo "  Expected format: YYYY-MM-DD (e.g., 2026-01-18)"
    exit 1
fi

# Configuration
# Get repo root directory (one level up from scripts/)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/.backup}"
APP_NAME="dnd-maroto"
REMOTE_DATA_PATH="/home/foundry/data"

# Create output directory with date parameter
OUTPUT_DIR="${BASE_OUTPUT_DIR}/${DATE_PARAM}"

echo "=========================================="
echo "Fetching file list from remote server..."
echo "Backing up all folders inside: ${REMOTE_DATA_PATH}"
echo "=========================================="

# Fetch the list of all files from the remote server
REMOTE_FILES=$(flyctl ssh console -a "${APP_NAME}" -C "find ${REMOTE_DATA_PATH} -type f" 2>/dev/null)

if [ -z "${REMOTE_FILES}" ]; then
    echo "✗ Failed to fetch file list from remote server."
    echo "  Make sure you're logged into fly.io (run: flyctl auth login)"
    exit 1
fi

# Convert the output to an array
mapfile -t FILES_TO_BACKUP <<< "${REMOTE_FILES}"

echo "Found ${#FILES_TO_BACKUP[@]} files to backup."
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "=========================================="
    echo "DRY RUN MODE - No files will be downloaded"
    echo "Date: ${DATE_PARAM}"
    echo "Output directory would be: ${OUTPUT_DIR}"
    echo "=========================================="
    echo ""
else
    # Create output directory with date parameter
    mkdir -p "${OUTPUT_DIR}"
    
    echo "=========================================="
    echo "Starting backup process..."
    echo "Date: ${DATE_PARAM}"
    echo "Output directory: ${OUTPUT_DIR}"
    echo "=========================================="
    echo ""
fi

echo "=========================================="
echo ""

# Backup each file/directory
for file_path in "${FILES_TO_BACKUP[@]}"; do
    if [ "$DRY_RUN" = true ]; then
        echo "Would backup: ${file_path}"
    else
        echo "------------------------------------------"
        echo "Backing up: ${file_path}"
    fi
    
    # Extract the path structure (without the "data" prefix)
    # Example: /home/foundry/data/Backups/worlds/... -> Backups/worlds/...
    if [[ "${file_path}" == *"${REMOTE_DATA_PATH}"* ]]; then
        # Get everything after /home/foundry/data/ (don't preserve the data folder)
        relative_path="${file_path#*${REMOTE_DATA_PATH}/}"
        
        # Get the directory path and filename
        if [ "$(dirname "${relative_path}")" = "." ]; then
            # File is directly in data folder
            local_dir="${OUTPUT_DIR}"
        else
            local_dir="${OUTPUT_DIR}/$(dirname "${relative_path}")"
        fi
        file_name=$(basename "${file_path}")
        
        # Download to the preserved structure
        local_file_path="${local_dir}/${file_name}"
    else
        # Fallback: if path doesn't match expected structure, just use filename
        file_name=$(basename "${file_path}")
        local_file_path="${OUTPUT_DIR}/${file_name}"
    fi
    
    # Print the local path where file would be saved
    echo "  → ${local_file_path}"
    
    # Skip actual backup if dry-run mode
    if [ "$DRY_RUN" = true ]; then
        echo ""
        continue
    fi
    
    # Create the directory structure
    mkdir -p "${local_dir}"
    
    # Skip if file already exists
    if [ -f "${local_file_path}" ]; then
        echo "⊘ Skipping (already exists): ${local_file_path}"
        echo ""
        continue
    fi
    
    flyctl ssh sftp get -a "${APP_NAME}" "${file_path}" "${local_file_path}"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully backed up: ${file_path} -> ${local_file_path}"
    else
        echo "✗ Failed to back up: ${file_path}"
    fi
    echo ""
done

echo "=========================================="
if [ "$DRY_RUN" = true ]; then
    echo "Dry run completed. ${#FILES_TO_BACKUP[@]} files would be backed up to: ${OUTPUT_DIR}"
else
    echo "Backup completed. Files saved to: ${OUTPUT_DIR}"
fi
echo "=========================================="