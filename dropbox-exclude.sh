#!/bin/bash

# Set Dropbox directory
DROPBOX_DIR="$HOME/Dropbox"
SEARCH_MODE="ever"
MINUTES=0
AUTO_CONFIRM=false
PATTERN="*"  # Default pattern

# Function to show usage
show_usage() {
    echo "Usage: $0 --pattern <glob-pattern> [--recent <minutes> | --ever] [--y]"
    echo "  --pattern <pattern> : Glob pattern to match directories (e.g. \"node_*\")"
    echo "  --recent <minutes>  : Only search directories modified in the last n minutes"
    echo "  --ever             : Search all directories (default)"
    echo "  --y                : Proceed without confirmation"
    echo "Example: $0 --pattern \"*node_*\" --recent 60 --y"
    exit 1
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --recent)
            if ! [[ $2 =~ ^[0-9]+$ ]]; then
                echo "Error: Minutes must be a number"
                show_usage
            fi
            SEARCH_MODE="recent"
            MINUTES="$2"
            shift 2
            ;;
        --ever)
            SEARCH_MODE="ever"
            shift
            ;;
        --y)
            AUTO_CONFIRM=true
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            show_usage
            ;;
    esac
done

# Check if pattern is provided
if [ "$PATTERN" = "*" ]; then
    echo "Error: Pattern must be specified using --pattern"
    show_usage
fi

echo "Searching for directories matching '$PATTERN' in $DROPBOX_DIR..."
if [ "$SEARCH_MODE" = "recent" ]; then
    echo "Looking for directories modified in the last $MINUTES minutes"
fi

# Construct the find command based on mode
if [ "$SEARCH_MODE" = "recent" ]; then
    FIND_CMD="find \"$DROPBOX_DIR\" -type d -mmin -${MINUTES} -name \"$PATTERN\" -print"
else
    FIND_CMD="find \"$DROPBOX_DIR\" -type d -name \"$PATTERN\" -print"
fi

# First, just list what we'll exclude (dry run)
echo -e "\nThe following directories will be excluded:"
eval $FIND_CMD

# Count the number of directories found
DIR_COUNT=$(eval $FIND_CMD | wc -l)

if [ "$DIR_COUNT" -eq 0 ]; then
    echo -e "\nNo matching directories found."
    exit 0
fi

# Handle confirmation
echo -e "\nFound $DIR_COUNT directory(ies) to exclude."
PROCEED=false

if [ "$AUTO_CONFIRM" = true ]; then
    PROCEED=true
    echo "Proceeding automatically due to --y flag"
else
    read -p "Do you want to proceed with excluding these directories? (y/n) " -n 1 -r
    echo    # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        PROCEED=true
    fi
fi

if [ "$PROCEED" = true ]
then
    # Actually exclude the directories
    eval $FIND_CMD | while read dir; do
        echo "Excluding: $dir"
        dropbox exclude add "$dir"
    done

    echo -e "\nExclusion complete. Current exclusion list:"
    dropbox exclude list
else
    echo "Operation cancelled"
fi