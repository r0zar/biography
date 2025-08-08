#!/bin/bash

# Progress Questioner Script
# Parses progress questions from weekly Covey reviews and presents them as notifications

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/progress-questioner.log"
}

log "Starting progress questioner session"

# Find the most recent weekly review file
LATEST_WEEKLY_REVIEW=$(find "$VAULT_DIR" -name "Weekly-Covey-Review-*.md" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

if [ -z "$LATEST_WEEKLY_REVIEW" ]; then
    log "No weekly review files found"
    exit 1
fi

if [ ! -f "$LATEST_WEEKLY_REVIEW" ]; then
    log "Latest weekly review file not found: $LATEST_WEEKLY_REVIEW"
    exit 1
fi

log "Found latest weekly review: $LATEST_WEEKLY_REVIEW"

# Parse progress questions from the weekly review
# Look for lines like: "Question text?" → Button options: "Option1/Option2"
QUESTIONS_FOUND=0

# Create temp file for questions
TEMP_QUESTIONS="/tmp/progress_questions_$(date +%s).txt"

# Extract questions using grep and awk
grep -n "→.*Button options:" "$LATEST_WEEKLY_REVIEW" | while IFS=':' read -r line_num rest; do
    # Get the line before this one (should contain the question)
    QUESTION_LINE=$((line_num - 1))
    
    if [ $QUESTION_LINE -gt 0 ]; then
        QUESTION=$(sed -n "${QUESTION_LINE}p" "$LATEST_WEEKLY_REVIEW" | sed 's/^[-* ]*//' | sed 's/^[[:space:]]*//')
        BUTTONS=$(echo "$rest" | sed 's/.*Button options: *"//' | sed 's/".*//' | tr '/' ' ')
        
        if [ -n "$QUESTION" ] && [ -n "$BUTTONS" ]; then
            echo "$QUESTION|$BUTTONS" >> "$TEMP_QUESTIONS"
            log "Found progress question: $QUESTION"
            QUESTIONS_FOUND=$((QUESTIONS_FOUND + 1))
        fi
    fi
done

# Check if we found any questions
if [ ! -f "$TEMP_QUESTIONS" ] || [ ! -s "$TEMP_QUESTIONS" ]; then
    log "No progress questions found in weekly review"
    exit 0
fi

ACTUAL_QUESTIONS=$(wc -l < "$TEMP_QUESTIONS" 2>/dev/null || echo 0)
log "Found $ACTUAL_QUESTIONS progress questions to present"

# Present each question as a notification
while IFS='|' read -r question buttons; do
    if [ -n "$question" ] && [ -n "$buttons" ]; then
        # Parse button labels (expecting exactly 2)
        POSITIVE_LABEL=$(echo "$buttons" | awk '{print $1}')
        NEGATIVE_LABEL=$(echo "$buttons" | awk '{print $2}')
        
        # Default to Good/Poor if parsing fails
        if [ -z "$POSITIVE_LABEL" ]; then
            POSITIVE_LABEL="Good"
        fi
        if [ -z "$NEGATIVE_LABEL" ]; then
            NEGATIVE_LABEL="Poor"
        fi
        
        log "Presenting question: $question (Options: $POSITIVE_LABEL/$NEGATIVE_LABEL)"
        
        # Present the notification and wait for response
        "$SCRIPTS_DIR/utils/progress-notification.py" "$question" "$POSITIVE_LABEL" "$NEGATIVE_LABEL"
        
        # Small delay between questions to avoid overwhelming the user
        sleep 2
    fi
done < "$TEMP_QUESTIONS"

# Clean up temp file
rm -f "$TEMP_QUESTIONS"

log "Progress questioner session completed"