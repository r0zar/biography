#!/bin/bash

# Covey Weekly Progress Review Script
# Generates progress assessment and next week focus without conflicting with monthly plans

# Auto-load configuration
source "$(dirname "$0")/../utils/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$COVEY_LOG"
}

log "Starting Covey weekly progress review"

# Skip if it's the 1st of the month (full analysis day)
if [ $(date +%d) -eq 01 ]; then
    log "Skipping weekly review - monthly comprehensive analysis runs today"
    exit 0
fi

# Generate timestamp for output file
TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
DATE_READABLE=$(date '+%B %d, %Y at %I:%M %p')
WEEK_OF=$(date '+%B %d, %Y')

# Check if current month's Covey analysis exists
CURRENT_MONTH_ANALYSIS="$VAULT_DIR/Covey-Life-Analysis.md"
if [ ! -f "$CURRENT_MONTH_ANALYSIS" ]; then
    log "No current month Covey analysis found - cannot perform weekly review"
    exit 1
fi

# Get question count and progress metrics
log "Analyzing current progress metrics"
QUESTION_COUNT=$("$SCRIPTS_DIR/utils/extract-qa-data.py" count)

# Parse checkbox completion from ADHD tasks and Covey analysis
ADHD_TASKS_FILE="$VAULT_DIR/ADHD-Tasks.md"
CHECKBOX_COMPLETED=0
CHECKBOX_TOTAL=0

if [ -f "$ADHD_TASKS_FILE" ]; then
    CHECKBOX_COMPLETED=$(grep -c "^- \[x\]" "$ADHD_TASKS_FILE" 2>/dev/null || echo 0)
    CHECKBOX_PENDING=$(grep -c "^- \[ \]" "$ADHD_TASKS_FILE" 2>/dev/null || echo 0)
    CHECKBOX_TOTAL=$((CHECKBOX_COMPLETED + CHECKBOX_PENDING))
fi

# Parse Covey analysis checkboxes too
if [ -f "$CURRENT_MONTH_ANALYSIS" ]; then
    COVEY_COMPLETED=$(grep -c "^- \[x\]" "$CURRENT_MONTH_ANALYSIS" 2>/dev/null || echo 0)
    COVEY_PENDING=$(grep -c "^- \[ \]" "$CURRENT_MONTH_ANALYSIS" 2>/dev/null || echo 0)
    
    CHECKBOX_COMPLETED=$((CHECKBOX_COMPLETED + COVEY_COMPLETED))
    CHECKBOX_TOTAL=$((CHECKBOX_TOTAL + COVEY_COMPLETED + COVEY_PENDING))
fi

# Calculate completion rate
COMPLETION_RATE=0
if [ $CHECKBOX_TOTAL -gt 0 ]; then
    COMPLETION_RATE=$((CHECKBOX_COMPLETED * 100 / CHECKBOX_TOTAL))
fi

log "Found $CHECKBOX_COMPLETED/$CHECKBOX_TOTAL tasks completed ($COMPLETION_RATE%)"

# Create weekly review prompt
WEEKLY_REVIEW_FILE="$VAULT_DIR/Weekly-Covey-Review-${TIMESTAMP}.md"

cat > /tmp/weekly_covey_prompt.txt << EOF
Please create a Covey weekly progress review:

1. Read the current month's comprehensive analysis at $CURRENT_MONTH_ANALYSIS
2. Read the current ADHD tasks at $ADHD_TASKS_FILE 
3. Read the most recent daily summary files in $VAULT_DIR (files named 2025-*.md from this week)

Create 'Weekly-Covey-Review-${TIMESTAMP}.md' in $VAULT_DIR with:

**HEADER INFORMATION:**
- Review Date: ${DATE_READABLE}
- Week of: ${WEEK_OF}
- Current Task Completion Rate: ${COMPLETION_RATE}% (${CHECKBOX_COMPLETED}/${CHECKBOX_TOTAL})
- Data Snapshot: Based on $QUESTION_COUNT total biography responses

**WEEKLY REVIEW SECTIONS:**

### Progress Assessment
- Brief review of key accomplishments this week
- Areas where progress was made toward monthly goals
- Patterns observed in daily summaries and task completion

### Challenge Areas Identified  
- Tasks or areas with low completion rates
- Obstacles that emerged this week
- Gaps between intentions and actions

### Next Week Focus
- 3-5 specific actions for the coming week
- Priorities based on monthly plan + this week's learnings
- Adjustments to approach based on what's working/not working

### Progress Questions for User
Generate 2-3 targeted questions about areas needing attention, formatted for notification system:
- Questions should be yes/no or binary choice format  
- Focus on areas with <50% completion or identified challenges
- Use format: "Question text?" → Button options: "Option1/Option2"

**STYLE NOTES:**
- Keep it concise (2-3 pages max vs comprehensive monthly analysis)
- Focus on actionable insights for next week
- Reference specific items from monthly plan
- Use Covey principles but don't repeat full framework
- Include internal links to relevant topics

This is a progress review, not a new comprehensive analysis. Build on the existing monthly plan.
EOF

# Use claude_wrapper to execute the weekly review prompt
log "Generating weekly Covey progress review"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" < /tmp/weekly_covey_prompt.txt

# Clean up temp file
rm -f /tmp/weekly_covey_prompt.txt

# Trigger progress questions if the review was generated successfully
if [ -f "$WEEKLY_REVIEW_FILE" ]; then
    log "Triggering progress questions from weekly review"
    # Small delay to ensure file is fully written
    sleep 2
    "$SCRIPTS_DIR/utils/progress-questioner.sh" &
    log "Progress questioner started in background"
fi

log "Weekly Covey progress review completed"