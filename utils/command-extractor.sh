#!/bin/bash

# Command Extractor - Extracts and executes topic-manager commands from Claude output
# Looks for lines like: "$SCRIPTS_DIR/utils/topic-manager.sh add-question ..."

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/command-extractor.log"
}

log "Starting command extraction and execution"

# Check if Claude output file was provided
CLAUDE_OUTPUT_FILE="$1"
if [ -z "$CLAUDE_OUTPUT_FILE" ] || [ ! -f "$CLAUDE_OUTPUT_FILE" ]; then
    log "No Claude output file provided or file doesn't exist: $CLAUDE_OUTPUT_FILE"
    exit 1
fi

log "Processing Claude output from: $CLAUDE_OUTPUT_FILE"

# Extract topic-manager commands from Claude output
COMMANDS_FOUND=0
COMMANDS_EXECUTED=0

# Look for lines that contain topic-manager.sh commands
grep "$SCRIPTS_DIR/utils/topic-manager.sh" "$CLAUDE_OUTPUT_FILE" | while IFS= read -r command_line; do
    # Clean up the command line - remove markdown formatting and leading/trailing characters
    CLEAN_COMMAND=$(echo "$command_line" | sed 's/^[- ]*//g' | sed 's/`//g' | sed 's/\*//g' | xargs)
    
    # Verify it's a valid topic-manager.sh command
    if [[ "$CLEAN_COMMAND" == *"topic-manager.sh add-question"* ]]; then
        log "Found command: $CLEAN_COMMAND"
        COMMANDS_FOUND=$((COMMANDS_FOUND + 1))
        
        # Parse the command components to properly quote the question
        if [[ "$CLEAN_COMMAND" =~ topic-manager\.sh[[:space:]]+add-question[[:space:]]+\"([^\"]+)\"[[:space:]]+\"([^\"]+)\" ]]; then
            # Command is already properly quoted
            FINAL_COMMAND="$CLEAN_COMMAND"
        else
            # Need to parse and quote the command properly
            # Extract script path
            SCRIPT_PATH=$(echo "$CLEAN_COMMAND" | awk '{print $1}')
            
            # Extract everything after "add-question "
            ARGS_PART=$(echo "$CLEAN_COMMAND" | sed 's/.*add-question //')
            
            # Try to parse with existing quotes first
            if [[ "$ARGS_PART" =~ ^\"([^\"]+)\"[[:space:]]+\"([^\"]+)\"$ ]]; then
                TOPIC="${BASH_REMATCH[1]}"
                QUESTION="${BASH_REMATCH[2]}"
            else
                # No quotes, need to figure out where topic ends and question begins
                # Look for common topic patterns - capitalize first letters
                if [[ "$ARGS_PART" =~ ^(Job\ Search\ Strategy|Personal\ Effectiveness|Interview\ Performance|Career\ Transition|Weekly\ Planning|Family\ Relationships|Personal\ Finances)[[:space:]]+(.+)$ ]]; then
                    TOPIC="${BASH_REMATCH[1]}"
                    QUESTION="${BASH_REMATCH[2]}"
                elif [[ "$ARGS_PART" =~ ^([A-Z][a-zA-Z]*)[[:space:]]+(.+)$ ]]; then
                    # Single word topic
                    TOPIC="${BASH_REMATCH[1]}"
                    QUESTION="${BASH_REMATCH[2]}"
                else
                    log "Could not parse command format: $CLEAN_COMMAND"
                    continue
                fi
            fi
            
            FINAL_COMMAND="$SCRIPT_PATH add-question \"$TOPIC\" \"$QUESTION\""
        fi
        
        # Execute the properly formatted command
        log "Executing: $FINAL_COMMAND"
        if eval "$FINAL_COMMAND" 2>&1; then
            log "Command executed successfully: $FINAL_COMMAND"
            COMMANDS_EXECUTED=$((COMMANDS_EXECUTED + 1))
        else
            log "Command failed: $FINAL_COMMAND"
        fi
    fi
done

# Since the while loop runs in a subshell, we need to count again for the final log
FINAL_COMMANDS_FOUND=$(grep -c "$SCRIPTS_DIR/utils/topic-manager.sh" "$CLAUDE_OUTPUT_FILE")
log "Command extraction completed: found $FINAL_COMMANDS_FOUND commands"

# Verify some commands were executed
if [ "$FINAL_COMMANDS_FOUND" -gt 0 ]; then
    echo "✅ Extracted and executed $FINAL_COMMANDS_FOUND topic-manager commands"
else
    echo "ℹ️  No topic-manager commands found in Claude output"
fi

log "Command extraction session completed"