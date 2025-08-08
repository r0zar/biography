#!/bin/bash

# ADHD-Friendly Task Prioritizer
# Reads Covey analysis, daily summary, and recent Q&A data to create prioritized weekly tasks
# Focuses on the 30-Day Effectiveness Plan from whatever Covey analysis exists

# Auto-load configuration
source "$(dirname "$0")/../utils/auto-config.sh"

DATE_TODAY=$(date '+%Y-%m-%d')
DATE_READABLE=$(date '+%B %d, %Y')

# Task file paths
ARCHIVED_DIR="$VAULT_DIR/Archived"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/adhd-task-prioritizer.log"
}

log "Starting ADHD-friendly task prioritization for $DATE_TODAY"

# Archive existing task file if it exists
if [ -f "$ADHD_TASKS_FILE" ]; then
    mkdir -p "$ARCHIVED_DIR"
    TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
    mv "$ADHD_TASKS_FILE" "$ARCHIVED_DIR/ADHD-Tasks-${TIMESTAMP}.md"
    log "Archived previous task file to $ARCHIVED_DIR/ADHD-Tasks-${TIMESTAMP}.md"
fi

# Get current week number (1-4 of the month for plan tracking)
CURRENT_WEEK=$(date '+%U')
MONTH_START_WEEK=$(date -d "$(date '+%Y-%m-01')" '+%U')
WEEK_OF_MONTH=$(( (CURRENT_WEEK - MONTH_START_WEEK + 1) ))

log "Current week of analysis cycle: Week $WEEK_OF_MONTH"

# Get recent Q&A count and data
QA_COUNT=$("$SCRIPTS_DIR/utils/extract-qa-data.py" count)
log "Found $QA_COUNT answered questions from today"

# Create the prioritized task list using Claude
TASK_PROMPT="I need you to create an ADHD-friendly daily task list based on my current effectiveness analysis and recent Q&A responses. Please:

1. Read my current Covey Life Analysis at $COVEY_FILE (focus on the 30-Day Effectiveness Plan section)
2. Read my today's daily summary at $VAULT_DIR/$DATE_TODAY.md to understand current context
3. Get my recent Q&A data using the extract-qa-data.py script: $SCRIPTS_DIR/utils/extract-qa-data.py
4. Read recent questions from Weekly Planning topic: $TOPICS_DIR/Weekly Planning.md

Based on this data, create a prioritized task file at $ADHD_TASKS_FILE with:

## ADHD-Friendly Task Format:
- **VERY specific, actionable tasks** (not vague goals)
- **Time estimates** for each task (5-30 minutes max per task)
- **Priority levels**: 🔥 URGENT (do first), ⭐ IMPORTANT (do today), 📋 WHEN POSSIBLE (do if time)
- **Week-based organization** following the current 30-Day Effectiveness Plan from the Covey analysis
- **CRITICAL**: Use proper markdown checkbox format [ ] for each task item so they can be checked off in Obsidian

## Content Structure:
# ADHD-Friendly Daily Tasks

- **Current Week Focus**: Based on which week of the 30-day plan we should be in
- **Today's Priority Tasks**: 3-5 specific tasks from the plan
- **This Week's Goals**: What should be accomplished this week according to the plan
- **Quick Wins**: 5-10 minute tasks that build momentum
- **Context**: Reference recent Q&A patterns and current challenges

## Key Requirements:
- Break large goals into tiny, specific actions
- Include time estimates for ADHD time-blindness
- Prioritize based on the Covey plan's weekly structure
- Reference mission statement alignment from analysis
- Include accountability mechanisms (tell girlfriend, log progress, etc.)
- **FORMAT ALL TASKS AS CHECKBOXES**: Use - [ ] Task description (time) format for every single actionable item
- Convert any existing bullet points or dashes to proper checkbox format [ ] 

Make tasks so specific that there's no ambiguity about what to do next. Focus on the current week's priorities from whatever 30-Day Plan exists in the analysis.

EXAMPLE FORMAT:
- [ ] Write down tomorrow's top 3 priorities (5 min)
- [ ] Submit one job application (20 min)  
- [ ] Practice breathing technique 3 times (10 min)"

log "Calling Claude to generate ADHD-friendly task prioritization"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$TASK_PROMPT"

log "ADHD task prioritization completed"

# Show the generated task file if it exists
TASK_FILE="$CURRENT_TASK_FILE"
if [ -f "$TASK_FILE" ]; then
    echo "Created ADHD-friendly task list: $TASK_FILE"
    echo ""
    echo "=== Today's Priority Tasks ==="
    grep -A 10 "Today's Priority Tasks" "$TASK_FILE" 2>/dev/null || echo "Task file created but section not found"
else
    echo "Task file was not created. Check logs for details."
fi

log "ADHD task prioritizer session completed"