#!/bin/bash

# Daily Summary Wrapper - Coordinates Q&A extraction and narrative generation

# Auto-load configuration
source "$(dirname "$0")/../utils/auto-config.sh"

DATE_TODAY=$(date '+%Y-%m-%d')
DAILY_FILE="$VAULT_DIR/$DATE_TODAY.md"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/daily-summary.log"
}

log "Starting daily summary creation for $DATE_TODAY"

# Get question count
QUESTION_COUNT=$("$SCRIPTS_DIR/utils/extract-qa-data.py" count)
log "Found $QUESTION_COUNT answered questions from today"

if [ "$QUESTION_COUNT" -eq 0 ]; then
    log "No questions answered today, skipping summary"
    echo "No questions were answered today."
    exit 0
fi

# Generate narrative using Claude
log "Generating narrative..."
NARRATIVE_OUTPUT=$("$SCRIPTS_DIR/utils/generate-narrative.sh" 2>&1)
NARRATIVE_EXIT_CODE=$?

log "Narrative generation exit code: $NARRATIVE_EXIT_CODE"
log "Narrative output length: ${#NARRATIVE_OUTPUT}"
log "First 200 chars of output: ${NARRATIVE_OUTPUT:0:200}"

if [ $NARRATIVE_EXIT_CODE -eq 0 ] && [ -n "$NARRATIVE_OUTPUT" ] && [ ${#NARRATIVE_OUTPUT} -gt 100 ]; then
    NARRATIVE="$NARRATIVE_OUTPUT"
    log "Successfully captured narrative: ${#NARRATIVE} characters"
else
    NARRATIVE="Unable to generate narrative at this time."
    log "Failed to generate narrative - Exit code: $NARRATIVE_EXIT_CODE, Output: '$NARRATIVE_OUTPUT'"
fi

# Create the daily summary file
log "Creating daily summary file: $DAILY_FILE"

cat > "$DAILY_FILE" << EOF
# Daily Portrait - $(date '+%B %d, %Y')

*A personal narrative based on today's biography questions*

---

$NARRATIVE

---

**Questions explored today:** $QUESTION_COUNT  
*Generated on $(date '+%Y-%m-%d at %I:%M %p')*

## Today's Q&A Summary

---

[[Biography]] | [[$(date -d yesterday '+%Y-%m-%d')]] | [[$(date -d tomorrow '+%Y-%m-%d')]]

#daily #portrait #biography #$(date '+%Y') #$(date '+%B' | tr '[:upper:]' '[:lower:]')
EOF

log "Daily summary created: $DAILY_FILE"
echo "$DAILY_FILE"