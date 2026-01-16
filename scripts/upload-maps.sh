#!/bin/bash

# Ensure script is run with bash (not sh)
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Parse command line arguments
DRY_RUN=false
NUMBER_OF_FILES=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --number-of-files)
            if [ -z "$2" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "✗ Error: --number-of-files requires a positive integer"
                exit 1
            fi
            NUMBER_OF_FILES="$2"
            shift 2
            ;;
        --number-of-files=*)
            NUMBER_OF_FILES="${1#*=}"
            if [ -z "$NUMBER_OF_FILES" ] || ! [[ "$NUMBER_OF_FILES" =~ ^[0-9]+$ ]]; then
                echo "✗ Error: --number-of-files requires a positive integer"
                exit 1
            fi
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--number-of-files=N]"
            echo "  Uploads all folders inside .maps to Foundry server"
            echo ""
            echo "Options:"
            echo "  --dry-run              List files without uploading"
            echo "  --number-of-files=N    Upload only the first N files (optional)"
            exit 0
            ;;
        *)
            echo "✗ Error: Unknown option: $1"
            echo "  Use --help for usage information"
            exit 1
            ;;
    esac
done

# Configuration
# Get repo root directory (one level up from scripts/)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAPS_DIR="${REPO_ROOT}/.maps"
APP_NAME="dnd-maroto"
REMOTE_BASE_PATH="/home/foundry/data/Data/assets/Maps"
UPLOAD_HISTORY_FILE="${MAPS_DIR}/upload-history"

# Check if .maps directory exists
if [ ! -d "${MAPS_DIR}" ]; then
    echo "✗ Error: .maps directory not found at: ${MAPS_DIR}"
    exit 1
fi

# Create upload history file if it doesn't exist
touch "${UPLOAD_HISTORY_FILE}"

# Load upload history into an associative array for fast lookup
declare -A UPLOAD_HISTORY
if [ -f "${UPLOAD_HISTORY_FILE}" ] && [ -s "${UPLOAD_HISTORY_FILE}" ]; then
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        UPLOAD_HISTORY["$line"]=1
    done < "${UPLOAD_HISTORY_FILE}"
    HISTORY_COUNT=${#UPLOAD_HISTORY[@]}
    echo "Loaded ${HISTORY_COUNT} files from upload history."
fi

echo "=========================================="
echo "Uploading maps to Foundry server..."
echo "Source: ${MAPS_DIR}"
echo "Destination: ${REMOTE_BASE_PATH}"
echo "=========================================="
echo ""

# Find all files in .maps directory recursively (excluding upload-history file)
mapfile -t ALL_FILES < <(find "${MAPS_DIR}" -type f ! -name "upload-history")

if [ ${#ALL_FILES[@]} -eq 0 ]; then
    echo "✗ No files found in .maps directory"
    exit 1
fi

# Filter out files that are already in upload history
FILTERED_FILES=()
SKIPPED_FROM_HISTORY=0

for file in "${ALL_FILES[@]}"; do
    # Get relative path from .maps directory
    relative_path="${file#${MAPS_DIR}/}"
    
    # Check if file is in upload history
    if [[ -n "${UPLOAD_HISTORY[$relative_path]}" ]]; then
        ((SKIPPED_FROM_HISTORY++))
        continue
    fi
    
    FILTERED_FILES+=("$file")
done

if [ ${SKIPPED_FROM_HISTORY} -gt 0 ]; then
    echo "Skipped ${SKIPPED_FROM_HISTORY} files already in upload history."
fi

# Update ALL_FILES to filtered list
ALL_FILES=("${FILTERED_FILES[@]}")

# Limit files if --number-of-files is specified
if [ -n "$NUMBER_OF_FILES" ]; then
    if [ "$NUMBER_OF_FILES" -gt ${#ALL_FILES[@]} ]; then
        echo "⚠ Warning: Requested ${NUMBER_OF_FILES} files, but only ${#ALL_FILES[@]} files found."
        echo "  Uploading all ${#ALL_FILES[@]} files."
        FILES_TO_UPLOAD=("${ALL_FILES[@]}")
    else
        FILES_TO_UPLOAD=("${ALL_FILES[@]:0:$NUMBER_OF_FILES}")
        echo "Found ${#ALL_FILES[@]} total files. Limiting to first ${#FILES_TO_UPLOAD[@]} files."
    fi
else
    FILES_TO_UPLOAD=("${ALL_FILES[@]}")
fi

echo "Found ${#ALL_FILES[@]} files to process (after filtering history)."
if [ ${SKIPPED_FROM_HISTORY} -gt 0 ]; then
    echo "  (${SKIPPED_FROM_HISTORY} files skipped from history)"
fi
if [ -n "$NUMBER_OF_FILES" ]; then
    echo "Uploading ${#FILES_TO_UPLOAD[@]} files (limited by --number-of-files=${NUMBER_OF_FILES})."
else
    echo "Uploading all ${#FILES_TO_UPLOAD[@]} files."
fi
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "=========================================="
    echo "DRY RUN MODE - No files will be uploaded"
    echo "=========================================="
    echo ""
fi

# Upload each file
UPLOADED=0
FAILED=0
SKIPPED=0

for local_file in "${FILES_TO_UPLOAD[@]}"; do
    # Get relative path from .maps directory
    # Example: /path/to/.maps/0.1.dungeon-big/file.jpg -> 0.1.dungeon-big/file.jpg
    relative_path="${local_file#${MAPS_DIR}/}"
    
    # Construct remote path
    remote_file_path="${REMOTE_BASE_PATH}/${relative_path}"
    
    # Get directory name for display
    folder_name=$(echo "${relative_path}" | cut -d'/' -f1)
    
    echo "------------------------------------------"
    echo "File: ${relative_path}"
    echo "  → ${remote_file_path}"
    
    # Skip actual upload if dry-run mode
    if [ "$DRY_RUN" = true ]; then
        echo ""
        continue
    fi
    
    # Check if file already exists on remote server
    flyctl ssh console -a "${APP_NAME}" -C "test -f '${remote_file_path}'" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "⊘ Skipping (already exists): ${relative_path}"
        ((SKIPPED++))
        # Record in upload history
        echo "${relative_path}" >> "${UPLOAD_HISTORY_FILE}"
        echo ""
        continue
    fi
    
    # Upload the file using flyctl ssh sftp put
    # Note: flyctl sftp put requires the remote directory to exist
    # We'll need to create the directory structure first if it doesn't exist
    
    # Extract remote directory path
    remote_dir=$(dirname "${remote_file_path}")
    
    # Create remote directory if it doesn't exist
    echo "  Creating remote directory: ${remote_dir}"
    flyctl ssh console -a "${APP_NAME}" -C "mkdir -p '${remote_dir}'" > /dev/null 2>&1
    
    echo "  Uploading file: ${local_file} to ${remote_file_path}"
    # Upload the file
    flyctl ssh sftp put -a "${APP_NAME}" "${local_file}" "${remote_file_path}"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully uploaded: ${relative_path}"
        ((UPLOADED++))
        # Record in upload history
        echo "${relative_path}" >> "${UPLOAD_HISTORY_FILE}"
    else
        echo "✗ Failed to upload: ${relative_path}"
        ((FAILED++))
    fi
    echo ""
done

echo "=========================================="
if [ "$DRY_RUN" = true ]; then
    echo "Dry run completed. ${#FILES_TO_UPLOAD[@]} files would be uploaded."
    if [ -n "$NUMBER_OF_FILES" ] && [ "$NUMBER_OF_FILES" -lt ${#ALL_FILES[@]} ]; then
        echo "  (${#ALL_FILES[@]} total files available)"
    fi
else
    echo "Upload completed!"
    echo "  Uploaded: ${UPLOADED}"
    echo "  Failed: ${FAILED}"
    echo "  Skipped (already exists): ${SKIPPED}"
    if [ ${SKIPPED_FROM_HISTORY} -gt 0 ]; then
        echo "  Skipped (from history): ${SKIPPED_FROM_HISTORY}"
    fi
    if [ -n "$NUMBER_OF_FILES" ] && [ "$NUMBER_OF_FILES" -lt ${#ALL_FILES[@]} ]; then
        echo "  (${#ALL_FILES[@]} total files available, ${#FILES_TO_UPLOAD[@]} processed)"
    fi
fi
echo "=========================================="

# Exit with error code if any uploads failed
if [ "$DRY_RUN" = false ] && [ ${FAILED} -gt 0 ]; then
    exit 1
fi

