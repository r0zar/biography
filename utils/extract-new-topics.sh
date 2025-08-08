#!/bin/bash

# Extract New Topics from Dimensional Analysis
# Finds [[links]] in analysis files and creates new QnA sections

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/topic-extraction.log"
}

log "Starting topic extraction from dimensional analyses"

# Find all Covey analysis files (handle spaces in path)
ANALYSIS_FILES=$(find "$VAULT_DIR" -name "Covey-Life-Analysis*.md")

# Extract unique [[links]] from all analysis files
if [ -n "$ANALYSIS_FILES" ]; then
    EXTRACTED_TOPICS=$(grep -ho '\[\[[^]]*\]\]' "$VAULT_DIR"/Covey-Life-Analysis*.md | sort | uniq | sed 's/\[\[\([^]]*\)\]\]/\1/')
else
    EXTRACTED_TOPICS=""
fi

log "Found topics: $EXTRACTED_TOPICS"

# Claude prompt to intelligently create focused topic pages
TOPIC_PROMPT="I'm enhancing the biography Q&A system to use focused topic pages based on dimensional analysis insights.

Please:
1. Read the current biography Q&A data at $BIOGRAPHY_FILE
2. Review these new topic suggestions extracted from the Covey analysis: 
   $(echo "$EXTRACTED_TOPICS" | tr '\n' ', ')

3. For each topic that would add value and isn't already covered well:
   - Use $SCRIPTS_DIR/utils/topic-manager.sh to create a focused Q&A page
   - Example: $SCRIPTS_DIR/utils/topic-manager.sh create \"Career Transition\"
   - Then add 5-7 relevant Yes/No questions to the topic page
   - Example: $SCRIPTS_DIR/utils/topic-manager.sh add-question \"Career Transition\" \"Have you set specific deadlines for your career transition milestones?\"

4. Focus on creating focused pages only for topics that:
   - Are highly relevant to current life situation and circumstances
   - Would benefit from having 10+ focused questions  
   - Emerge naturally from the analysis and current Biography.md content
   - Don't duplicate existing topic coverage

5. Only create topics that would genuinely deepen understanding and provide actionable insights
6. Don't duplicate existing coverage - enhance it with focused depth

The goal is to create organized, searchable topic pages rather than growing the main Biography.md file."

# Use claude_wrapper to execute the topic extraction and page creation
log "Calling claude_wrapper to create focused topic pages"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$TOPIC_PROMPT"

log "Topic extraction and integration completed"