#!/bin/bash

# Quick Question Script
# Presents a single question from piped input or command line argument

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Set GUI environment variables for proper dialog display
export DISPLAY="${DISPLAY:-:1}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/quick-question.log"
}

log "Starting quick question session"

# Get question text from pipe or argument
if [ $# -gt 0 ]; then
    QUESTION="$*"
elif [ ! -t 0 ]; then
    # Read from pipe
    QUESTION=$(cat)
else
    echo "Usage: $0 \"Question text\" OR echo \"Question text\" | $0"
    exit 1
fi

if [ -z "$QUESTION" ]; then
    log "No question provided"
    echo "Error: No question text provided"
    exit 1
fi

log "Processing question: $QUESTION"

# Execute generic prompt notification through Claude and route through topic manager
GENERIC_PROMPT="Please present this question to the user and save the answer to the biography system:

QUESTION: $QUESTION

SYSTEM INFO:
- OS: $(uname -s) $(uname -r)
- Desktop: ${XDG_CURRENT_DESKTOP:-Unknown}
- Display: ${DISPLAY:-Not set}

TASK:
1. Present the question using the best available interface (notify-send, zenity, etc.)
2. Capture the user's response
3. Route the question and answer through the topic-manager system:
   - Use topic-manager.sh to route the question to the most appropriate topic
   - Update the topic file with the question and answer
   - Use proper status symbols (✅ for answered questions)
   - Add timestamp for the answer

DIALOG PRESENTATION:
- PREFERRED: Use notify-send with -A parameters for interactive responses
  * Returns numeric index: 0=first button, 1=second button, etc.  
  * More reliable than dialog windows for text visibility
  * Integrates naturally with desktop environment
- FALLBACK: Use zenity or other dialog tools for complex interactions
- Current GTK_THEME is set to: ${GTK_THEME:-default}

TOPIC ROUTING:
After getting the user's response, use the topic-manager to save it:
- Call: $SCRIPTS_DIR/utils/topic-manager.sh route-question \"$QUESTION\"
- Then: $SCRIPTS_DIR/utils/topic-manager.sh update-status \"question_text\" \"✅\" \"answer_text\"
- This ensures the Q&A is properly saved to the biography system"

log "Presenting question and routing through topic manager"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$GENERIC_PROMPT"

log "Quick question session completed"