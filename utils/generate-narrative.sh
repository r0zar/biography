#!/bin/bash

# Generate narrative using Claude from Q&A data

# Auto-load configuration
source "$(dirname "$0")/utils/auto-config.sh"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/daily-summary.log"
}

# Get Q&A data and pronouns
QA_DATA=$("$SCRIPTS_DIR/utils/extract-qa-data.py")
PRONOUN_DATA=$("$SCRIPTS_DIR/utils/extract-qa-data.py" pronouns)
QUESTION_COUNT=$("$SCRIPTS_DIR/utils/extract-qa-data.py" count)

# Parse pronouns
IFS='|' read -r PRONOUN POSSESSIVE OBJECTIVE <<< "$PRONOUN_DATA"

log "Generating narrative for $QUESTION_COUNT questions using pronouns: $PRONOUN/$POSSESSIVE/$OBJECTIVE"

# Create Claude prompt (more direct)
PROMPT="Based on the Q&A data below, write a personal narrative about this person. Use third person ($PRONOUN/$POSSESSIVE/$OBJECTIVE) pronouns. Write 2-3 paragraphs capturing who they are, their current situation, and what makes them unique. Return only the narrative text."

# Call Claude wrapper with piped data
log "Calling Claude via pipe with ${#QA_DATA} characters of Q&A data"

NARRATIVE=$(echo "$QA_DATA" | claude --model opus -p "$PROMPT")

if [ -n "$NARRATIVE" ] && [ ${#NARRATIVE} -gt 50 ]; then
    log "Successfully generated narrative: ${#NARRATIVE} characters"
    echo "$NARRATIVE"
else
    log "Claude failed or returned minimal output, using fallback"
    echo "Today $PRONOUN answered $QUESTION_COUNT questions across various topics, demonstrating ongoing self-reflection during $POSSESSIVE current life transition and career development journey."
fi