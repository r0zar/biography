#!/bin/bash

# Monthly Planning Generator
# Creates comprehensive monthly planning analysis using Covey 7 Habits framework

# Auto-load configuration and logging
source "$(dirname "$0")/../utils/auto-config.sh"
source "$(dirname "$0")/../utils/logger.sh"

log_start "Monthly planning analysis session"

# Generate timestamp for archiving
TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
DATE_READABLE=$(date '+%B %d, %Y at %I:%M %p')

# Archive existing analysis if it exists
ARCHIVED_DIR="$VAULT_DIR/Archived"

if [ -f "$MONTHLY_PLANNING_FILE" ]; then
    mkdir -p "$ARCHIVED_DIR"
    mv "$MONTHLY_PLANNING_FILE" "$ARCHIVED_DIR/Monthly Planning-${TIMESTAMP}.md"
    log_info "Archived previous monthly planning to $ARCHIVED_DIR/Monthly Planning-${TIMESTAMP}.md"
fi

# Get question count for metadata
log_info "Getting question count for analysis metadata"
# Get question count from topic files
QUESTION_COUNT=$(find "$VAULT_DIR/Topics" -name "*.md" -exec grep -c "✅.*answered $(date '+%Y-%m-%d')" {} + | awk '{sum+=$1} END {print sum+0}')
log_info "Found $QUESTION_COUNT answered questions for analysis"

# Create Covey analysis prompt
cat > /tmp/covey_prompt.txt << EOF
Please perform a Stephen Covey dimensional analysis:

1. Read the agent instructions at $COVEY_PROMPT_FILE
2. Read the main biography data at $BIOGRAPHY_FILE  
3. Read ALL topic-specific Q&A files in $TOPICS_DIR directory (these contain specialized questions and responses)
4. Read the personal mission statement at $MISSION_FILE to understand core values, life purpose, and aspirations
5. Create 'Monthly Planning.md' in $VAULT_DIR

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
log_info "Calling claude_wrapper with simplified Stephen Covey analysis prompt"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue < /tmp/covey_prompt.txt

# Clean up temp file
rm -f /tmp/covey_prompt.txt

# Post-analysis: Deep organizational review of topics and patterns
log_info "Conducting thorough organizational review of topics and underlying patterns"

cat > /tmp/topic_review_prompt.txt << EOF
MONTHLY TOPIC ORGANIZATION & PATTERN ANALYSIS

Now that the Monthly Planning analysis is complete, perform a comprehensive organizational review to explore the WHY behind the last 30 days of data.

**DEEP PATTERN EXPLORATION:**

1. **ROOT CAUSE ANALYSIS** - For each major theme identified in the Monthly Planning:
   - What underlying beliefs, fears, or motivations drive these patterns?
   - Which responses reveal recurring emotional or psychological themes?
   - What systemic issues emerge from the 30-day data snapshot?

2. **TOPIC SYSTEM OPTIMIZATION:**
   - Review all existing topics in $VAULT_DIR/Topics for relevance and depth
   - Identify gaps where important WHY questions are missing
   - Find topics that could be consolidated for better insight generation
   - Discover emerging themes that need dedicated topic areas

3. **STRATEGIC QUESTION DEVELOPMENT:**
   - Generate 3-5 deep exploratory questions for each major pattern area
   - Focus on WHY questions that get to root motivations and blocks
   - Create questions that explore the gap between values and actions
   - Develop questions that examine systemic patterns vs one-off events

4. **TOPIC MANAGEMENT ACTIONS:**
   Execute these commands based on your analysis:
   
   For consolidation:
   - Use: $SCRIPTS_DIR/utils/topic-manager.sh consolidate "Topic Name"
   
   For new strategic topics:
   - Use: $SCRIPTS_DIR/utils/topic-manager.sh create "Deep Topic Name"
   
   For adding exploratory questions:
   - Use: $SCRIPTS_DIR/utils/topic-manager.sh add-question "Topic" "Why-focused question?"

**FOCUS AREAS FOR WHY EXPLORATION:**
- Why do completion rates vary dramatically across different life areas?
- What underlying beliefs drive career transition resistance or momentum?
- Why do certain daily habits succeed while others consistently fail?
- What emotional patterns emerge around key life decisions and priorities?
- Why do some weeks show high effectiveness while others show avoidance?

**REQUIREMENTS:**
- Base all analysis on the actual 30-day data patterns, not generic advice
- Generate specific, actionable topic-manager.sh commands
- Focus on systemic WHY patterns rather than surface-level symptoms
- Create topics and questions that will yield deeper self-understanding over time

**OUTPUT FORMAT:**
1. Pattern analysis summary (what WHY themes emerged)
2. Specific topic-manager.sh commands to execute
3. Rationale for each organizational change

Execute the topic management commands you identify and report on the organizational improvements made.
EOF

# Execute the organizational review with Claude
"$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue < /tmp/topic_review_prompt.txt

# Clean up temp file
rm -f /tmp/topic_review_prompt.txt

log_end "Stephen Covey dimensional analysis session"