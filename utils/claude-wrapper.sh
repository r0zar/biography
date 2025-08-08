#!/bin/bash

# Dynamic Claude wrapper script
# Ensure PATH includes NVM path for Claude CLI

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

export PATH="$HOME/.nvm/versions/node/v22.17.0/bin:$PATH"
CLAUDE_PATH=$(which claude)
LOG_FILE="$LOGS_DIR/claude-cron.log"

# Check if claude was found
if [ -z "$CLAUDE_PATH" ]; then
    echo "$(date): Error: claude command not found in PATH" >> "$LOGS_DIR/claude-cron.log"
    
    # Send notification about error
    if [ -n "$DISPLAY" ] && command -v notify-send >/dev/null 2>&1; then
        notify-send "Claude Error" "Claude CLI not found in PATH" --urgency=critical
    fi
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Log the command being executed
{
    echo "==================== $(date '+%Y-%m-%d %H:%M:%S') ===================="
    echo "Command: claude $*"
    echo "Working Directory: $(pwd)"
    echo "----------------------------------------"
} >> "$LOG_FILE"

# Execute claude and capture output
OUTPUT=$("$CLAUDE_PATH" --dangerously-skip-permissions -p "$@" 2>&1)
EXIT_CODE=$?

# Log the output
echo "$OUTPUT" >> "$LOG_FILE"

# Also return output to caller
echo "$OUTPUT"

# Log completion
echo "Exit Code: $EXIT_CODE" >> "$LOG_FILE"
echo -e "==================== END ====================\n" >> "$LOG_FILE"

# Notify if there was an error
if [ $EXIT_CODE -ne 0 ]; then
    if [ -n "$DISPLAY" ] && command -v notify-send >/dev/null 2>&1; then
        notify-send "Claude Error" "Claude command failed with exit code $EXIT_CODE" \
            --urgency=critical \
            --expire-time=15000
    fi
fi

exit $EXIT_CODE