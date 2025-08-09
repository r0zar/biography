#!/bin/bash

# Daily Planning Generator
# Creates prioritized daily planning based on Covey analysis, daily retrospective, and Q&A data
# Focuses on the 30-Day Effectiveness Plan from current Covey analysis

# Auto-load configuration and logging
source "$(dirname "$0")/../utils/auto-config.sh"
source "$(dirname "$0")/../utils/logger.sh"

DATE_TODAY=$(date '+%Y-%m-%d')
DATE_READABLE=$(date '+%B %d, %Y')

# Task file paths
ARCHIVED_DIR="$VAULT_DIR/Archived"

log_start "Daily planning generation for $DATE_TODAY"

# Archive existing planning file if it exists
if [ -f "$DAILY_PLANNING_FILE" ]; then
    mkdir -p "$ARCHIVED_DIR"
    TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
    mv "$DAILY_PLANNING_FILE" "$ARCHIVED_DIR/Daily Planning-${TIMESTAMP}.md"
    log_info "Archived previous planning file to $ARCHIVED_DIR/Daily Planning-${TIMESTAMP}.md"
fi

# Get current week number (1-4 of the month for plan tracking)
CURRENT_WEEK=$(date '+%U')
MONTH_START_WEEK=$(date -d "$(date '+%Y-%m-01')" '+%U')
WEEK_OF_MONTH=$(( (CURRENT_WEEK - MONTH_START_WEEK + 1) ))

log_info "Current week of analysis cycle: Week $WEEK_OF_MONTH"

# Get recent Q&A count and data
# Get question count from topic files  
QA_COUNT=$(find "$VAULT_DIR/Topics" -name "*.md" -exec grep -c "✅.*answered $(date '+%Y-%m-%d')" {} + | awk '{sum+=$1} END {print sum+0}')
log_info "Found $QA_COUNT answered questions from today"

# Create the prioritized task list using Claude
TASK_PROMPT="I need you to create an ADHD-friendly daily task list based on my current effectiveness analysis and recent Q&A responses. Please:

1. Read my current Monthly Planning at $MONTHLY_PLANNING_FILE (focus on the 30-Day Effectiveness Plan section)
2. Read my today's daily summary at $VAULT_DIR/$DATE_TODAY.md to understand current context
3. Get my recent Q&A data by scanning topic files in $VAULT_DIR/Topics for answered questions
4. Read recent questions from Weekly Planning topic: $TOPICS_DIR/Weekly Planning.md

Based on this data, create a prioritized task file at $DAILY_PLANNING_FILE with:

## ADHD-Friendly Task Format:
- **VERY specific, actionable tasks** (not vague goals)
- **Time estimates** for each task (5-30 minutes max per task)
- **Priority levels**: 🔥 URGENT (do first), ⭐ IMPORTANT (do today), 📋 WHEN POSSIBLE (do if time)
- **Week-based organization** following the current 30-Day Effectiveness Plan from the Covey analysis
- **CRITICAL**: Use proper markdown checkbox format [ ] for each task item so they can be checked off in Obsidian

## Content Structure:
# Daily Planning

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

log_info "Calling Claude to generate daily planning"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue "$TASK_PROMPT"

log_info "Daily planning generation completed"

# Show the generated planning file if it exists
if [ -f "$DAILY_PLANNING_FILE" ]; then
    echo "Created daily planning: $DAILY_PLANNING_FILE"
    echo ""
    echo "=== Today's Priority Tasks ==="
    grep -A 10 "Today's Priority Tasks" "$DAILY_PLANNING_FILE" 2>/dev/null || echo "Planning file created but section not found"
else
    echo "Planning file was not created. Check logs for details."
fi

log_end "Daily planning generator session"