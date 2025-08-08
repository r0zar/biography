#!/bin/bash

# Stephen Covey Dimensional Analysis Script (Simple Version)
# Generates dimensional summary using Claude without interactive questions

# Auto-load configuration
source "$(dirname "$0")/../utils/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$COVEY_LOG"
}

log "Starting Stephen Covey dimensional analysis session (simple)"

# Generate timestamp for archiving
TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
DATE_READABLE=$(date '+%B %d, %Y at %I:%M %p')

# Archive existing analysis if it exists
ARCHIVED_DIR="$VAULT_DIR/Archived"

if [ -f "$COVEY_FILE" ]; then
    mkdir -p "$ARCHIVED_DIR"
    mv "$COVEY_FILE" "$ARCHIVED_DIR/Covey-Life-Analysis-${TIMESTAMP}.md"
    log "Archived previous analysis to $ARCHIVED_DIR/Covey-Life-Analysis-${TIMESTAMP}.md"
fi

# Get question count for metadata
log "Getting question count for analysis metadata"
QUESTION_COUNT=$("$SCRIPTS_DIR/utils/extract-qa-data.py" count)
log "Found $QUESTION_COUNT answered questions for analysis"

# Create Covey analysis prompt
cat > /tmp/covey_prompt.txt << EOF
Please perform a Stephen Covey dimensional analysis:

1. Read the agent instructions at $COVEY_PROMPT_FILE
2. Read the main biography data at $BIOGRAPHY_FILE  
3. Read ALL topic-specific Q&A files in $TOPICS_DIR directory (these contain specialized questions and responses)
4. Read the personal mission statement at $MISSION_FILE to understand core values, life purpose, and aspirations
5. Create 'Covey-Life-Analysis.md' in $VAULT_DIR

IMPORTANT ANALYSIS SCOPE:
- Total answered questions to analyze: $QUESTION_COUNT
- Include data from Biography.md AND all Topics/*.md files
- Allow the most significant life patterns and themes to emerge naturally from the data
- Do not focus solely on career - analyze ALL aspects of life effectiveness that show up in the responses
- MISSION ALIGNMENT: Assess current effectiveness patterns against the personal mission statement values: family devotion, protective leadership, creative expression, ethical integrity, purposeful wealth creation, and fighting injustice
- Identify the 2-3 most impactful areas for development based on what the data reveals

Follow all guidelines in the agent instructions file for analysis components, voice, style, and format. Pay special attention to how current behaviors and effectiveness patterns align with or diverge from the stated mission and values.

IMPORTANT: Include at the top of the document:
- Analysis Date: ${DATE_READABLE}
- Data Snapshot: Based on $QUESTION_COUNT biography responses through $(date '+%Y-%m-%d')
- Next Recommended Review: $(date -d '+1 week' '+%B %d, %Y')

OUTPUT NOTES:
- Use Obsidian-compatible markdown
- Include internal links: `[[Biography]]`, `[[Career Transition]]`
- Add relevant tags: `#covey #effectiveness #7habits #career`
- Include timestamp and review recommendations
- Structure with clear headings and bullet points

Also add at the bottom:
*This analysis reflects your situation as of ${DATE_READABLE} based on $QUESTION_COUNT answered questions across all biography topic areas. Your circumstances and responses may evolve, so periodic re-analysis is recommended.*
EOF

# Use claude_wrapper to execute the Covey analysis prompt
log "Calling claude_wrapper with simplified Stephen Covey analysis prompt"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" < /tmp/covey_prompt.txt

# Clean up temp file
rm -f /tmp/covey_prompt.txt

# Extract and integrate new topics from the analysis
log "Extracting new QnA topics from dimensional analysis"
"$SCRIPTS_DIR/utils/extract-new-topics.sh"

log "Stephen Covey dimensional analysis session completed"