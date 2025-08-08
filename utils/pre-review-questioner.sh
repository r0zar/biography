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

# Extract questions from Claude output
log "Analyzing Claude output file: $CLAUDE_OUTPUT_FILE"
log "File size: $(wc -c < "$CLAUDE_OUTPUT_FILE" 2>/dev/null || echo "0") bytes"

# Debug: Show first few lines of Claude output
log "First 10 lines of Claude output:"
head -10 "$CLAUDE_OUTPUT_FILE" >> "$LOGS_DIR/pre-review-questioner.log"

# Look for numbered questions with the format: "1. Question text? → Button options: "Option1/Option2""
QUESTIONS_FOUND=0
TEMP_QUESTIONS="/tmp/pre_review_questions_$(date +%s).txt"

# Extract questions using grep and parsing
log "Searching for numbered questions with button options..."
grep -n "^[0-9]\+\." "$CLAUDE_OUTPUT_FILE" | grep "→.*Button options:" | while IFS=':' read -r line_num line_content; do
    # Parse the question and button options
    QUESTION=$(echo "$line_content" | sed 's/^[0-9]*\. *//' | sed 's/ *→.*$//')
    BUTTONS=$(echo "$line_content" | sed 's/.*Button options: *"//' | sed 's/".*$//' | tr '/' ' ')
    
    # Remove markdown formatting from question text
    QUESTION=$(echo "$QUESTION" | sed 's/\*\*//g' | sed 's/\*//g' | sed 's/`//g')
    
    if [ -n "$QUESTION" ] && [ -n "$BUTTONS" ]; then
        echo "$QUESTION|$BUTTONS" >> "$TEMP_QUESTIONS"
        log "Found pre-review question: $QUESTION"
        QUESTIONS_FOUND=$((QUESTIONS_FOUND + 1))
    fi
done

# Check if we found any questions
if [ ! -f "$TEMP_QUESTIONS" ] || [ ! -s "$TEMP_QUESTIONS" ]; then
    log "No pre-review questions found in Claude output"
    exit 0
fi

ACTUAL_QUESTIONS=$(wc -l < "$TEMP_QUESTIONS" 2>/dev/null || echo 0)
log "Found $ACTUAL_QUESTIONS pre-review questions to present"

if [ "$ACTUAL_QUESTIONS" -gt 0 ]; then
    echo "===================================================="
    echo "PRE-REVIEW QUESTIONS"  
    echo "===================================================="
    echo "About to present $ACTUAL_QUESTIONS targeted questions"
    echo "to fill knowledge gaps before the weekly review."
    echo ""
    echo "These questions will appear as notifications."
    echo "Please answer them to improve the weekly analysis."
    echo "===================================================="
    echo ""
fi

# Present each question as a notification
while IFS='|' read -r question buttons; do
    if [ -n "$question" ] && [ -n "$buttons" ]; then
        # Parse button labels (expecting exactly 2)
        POSITIVE_LABEL=$(echo "$buttons" | awk '{print $1}')
        NEGATIVE_LABEL=$(echo "$buttons" | awk '{print $2}')
        
        # Default to clear Yes/No if parsing fails
        if [ -z "$POSITIVE_LABEL" ]; then
            POSITIVE_LABEL="Yes"
        fi
        if [ -z "$NEGATIVE_LABEL" ]; then
            NEGATIVE_LABEL="No"
        fi
        
        # Make sure labels are clear and descriptive
        # If they're too generic, enhance them
        if [ "$POSITIVE_LABEL" = "High" ]; then
            POSITIVE_LABEL="High/Strong"
        elif [ "$POSITIVE_LABEL" = "Good" ]; then
            POSITIVE_LABEL="Good/Working"
        fi
        
        if [ "$NEGATIVE_LABEL" = "Low" ]; then
            NEGATIVE_LABEL="Low/Weak"
        elif [ "$NEGATIVE_LABEL" = "Poor" ]; then
            NEGATIVE_LABEL="Poor/Broken"
        fi
        
        log "Presenting pre-review question: $question (Options: $POSITIVE_LABEL/$NEGATIVE_LABEL)"
        
        # Present the notification and wait for response
        "$SCRIPTS_DIR/utils/progress-notification.py" "$question" "$POSITIVE_LABEL" "$NEGATIVE_LABEL"
        
        # Small delay between questions to avoid overwhelming the user
        sleep 2
    fi
done < "$TEMP_QUESTIONS"

# Clean up temp file
rm -f "$TEMP_QUESTIONS"

log "Pre-review questioner session completed"