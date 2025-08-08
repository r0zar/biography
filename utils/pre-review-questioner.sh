#!/bin/bash

# Pre-Review Questioner Script
# Extracts pre-review questions from Claude output and presents them as notifications

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/pre-review-questioner.log"
}

log "Starting pre-review questioner session"

# Check if Claude output file exists (passed as argument)
CLAUDE_OUTPUT_FILE="$1"
if [ -z "$CLAUDE_OUTPUT_FILE" ] || [ ! -f "$CLAUDE_OUTPUT_FILE" ]; then
    log "No Claude output file provided or file doesn't exist: $CLAUDE_OUTPUT_FILE"
    exit 1
fi

log "Processing Claude output from: $CLAUDE_OUTPUT_FILE"

# Execute generic prompt for pre-review question processing through Claude
GENERIC_PROMPT="Please process this Claude output file and extract pre-review questions:

INPUT FILE: $CLAUDE_OUTPUT_FILE

CONTEXT:
- This file contains Claude analysis output with embedded pre-review questions
- Questions are formatted like: \"1. Question text? → Button options: Option1/Option2\"
- We need to extract and present these questions to fill knowledge gaps

TASK:
1. Read and analyze the Claude output file: $CLAUDE_OUTPUT_FILE
2. Extract numbered questions with button options format
3. For each question found:
   - Present it using the best available interface (notify-send, zenity, etc.)
   - Capture the user's response  
   - Route through topic-manager to save in appropriate topic file
   - Use proper status symbols (✅ for answered questions)
   - Add timestamps for answers

PROCESSING APPROACH:
- Look for pattern: \"[number]. [question text] → Button options: [options]\"
- Remove markdown formatting from question text
- Parse button options (usually Yes/No, High/Low, Good/Bad variants)
- Present each question with appropriate delay between them
- Save all responses to biography system via topic-manager routing

DIALOG PRESENTATION:
- PREFERRED: Use notify-send with -A parameters for interactive responses
- FALLBACK: Use zenity or other dialog tools for complex interactions
- Current system: $(uname -s) with desktop ${XDG_CURRENT_DESKTOP:-Unknown}
- Display: ${DISPLAY:-Not set}

TOPIC ROUTING:
After getting responses, use topic-manager to save:
- Call: $SCRIPTS_DIR/utils/topic-manager.sh route-question \"[question]\"
- Then: $SCRIPTS_DIR/utils/topic-manager.sh update-status \"[question]\" \"✅\" \"[answer]\"

OUTPUT:
Show user what questions were found and present them systematically.
Report success/completion when done."

log "Processing pre-review questions through Claude wrapper"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$GENERIC_PROMPT"

log "Pre-review questioner session completed"