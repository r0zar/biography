#!/bin/bash

# Biography Questions Script
# Uses Claude to generate intelligent, contextual biography questions

# Auto-load configuration
source "$(dirname "$0")/../utils/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$BIOGRAPHY_LOG"
}

log "Starting intelligent biography question session"

# First check if there are any pending questions that need to be answered
log "Checking for pending questions before generating new ones"
python3 "$SCRIPTS_DIR/utils/biography-notification.py" --check-pending-only 2>/dev/null
PENDING_CHECK_RESULT=$?

if [ $PENDING_CHECK_RESULT -eq 1 ]; then
    log "Found pending questions - presenting them for response instead of generating new ones"
    echo "⏳ Found pending questions - presenting them now..."
    
    # Present the pending questions for response
    "$SCRIPTS_DIR/utils/biography-notification.py"
    exit 0
fi

log "No pending questions found, proceeding with new question generation"

# Intelligent Claude prompt for generating contextual questions with smart topic routing
CLAUDE_PROMPT="I'm building a comprehensive biography through regular Yes/No question sessions using focused topic pages. Please:

1. First read the instructions at $BIOGRAPHY_PROMPT_FILE to understand your role and approach
2. Then read my current Q&A data at $BIOGRAPHY_FILE and scan existing topic pages to understand what I've already shared
3. Review my current Stephen Covey analysis at $COVEY_FILE to understand my development areas and effectiveness gaps
4. Read my personal mission statement at $MISSION_FILE to understand my core values, family aspirations, and life purpose
5. Generate ONE contextual Yes/No question that either:
   - Explores the most at-risk areas of my life based on the Covey analysis
   - Discovers new details of my life haven't been documented yet
   - OR addresses development areas identified in the Covey analysis 
   - OR helps assess alignment with my mission statement values (family devotion, creative expression, ethical integrity, wealth creation, fighting injustice)
6. Use $SCRIPTS_DIR/utils/topic-manager.sh route-question \"[your question]\" to determine the best topic file  
7. Add the question to the appropriate file using the topic-manager.sh script
8. Call "$SCRIPTS_DIR/utils/biography-notification.py" to send the interactive notification

The system will ALWAYS route questions to focused topic pages - never to Biography.md. Use both the Covey analysis insights and mission statement to generate more targeted questions that help assess progress toward life goals and address effectiveness gaps.

IMPORTANT: Never route questions to Biography.md. Always use topic pages. If no existing topic fits, create a new appropriate topic page.

The instructions file contains all the details about how to approach this task effectively."

# Use claude_wrapper to execute the intelligent biography prompt  
log "Calling claude_wrapper with intelligent biography prompt"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$CLAUDE_PROMPT"

# Always call the notification script after Claude is done
log "Calling notification script"
"$SCRIPTS_DIR/utils/biography-notification.py"

log "Intelligent biography question session completed"