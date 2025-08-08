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
PRIORITY_FILE="$VAULT_DIR/Priority-Management.md"
CHECKBOX_COMPLETED=0
CHECKBOX_TOTAL=0

if [ -f "$ADHD_TASKS_FILE" ]; then
    CHECKBOX_COMPLETED=$(grep -c "^- \[x\]" "$ADHD_TASKS_FILE" 2>/dev/null | head -1 || echo "0")
    CHECKBOX_PENDING=$(grep -c "^- \[ \]" "$ADHD_TASKS_FILE" 2>/dev/null | head -1 || echo "0")
    CHECKBOX_TOTAL=$((CHECKBOX_COMPLETED + CHECKBOX_PENDING))
fi

# Parse Covey analysis checkboxes too
if [ -f "$CURRENT_MONTH_ANALYSIS" ]; then
    COVEY_COMPLETED=$(grep -c "^- \[x\]" "$CURRENT_MONTH_ANALYSIS" 2>/dev/null | head -1 || echo "0")
    COVEY_PENDING=$(grep -c "^- \[ \]" "$CURRENT_MONTH_ANALYSIS" 2>/dev/null | head -1 || echo "0")
    
    # Ensure numeric values
    CHECKBOX_COMPLETED=${CHECKBOX_COMPLETED:-0}
    COVEY_COMPLETED=${COVEY_COMPLETED:-0}
    COVEY_PENDING=${COVEY_PENDING:-0}
    
    CHECKBOX_COMPLETED=$((CHECKBOX_COMPLETED + COVEY_COMPLETED))
    CHECKBOX_TOTAL=$((CHECKBOX_TOTAL + COVEY_COMPLETED + COVEY_PENDING))
fi

# Ensure variables are numeric and calculate completion rate
CHECKBOX_COMPLETED=${CHECKBOX_COMPLETED:-0}
CHECKBOX_TOTAL=${CHECKBOX_TOTAL:-0}
COMPLETION_RATE=0
if [ "$CHECKBOX_TOTAL" -gt 0 ] 2>/dev/null; then
    COMPLETION_RATE=$((CHECKBOX_COMPLETED * 100 / CHECKBOX_TOTAL))
fi

log "Found $CHECKBOX_COMPLETED/$CHECKBOX_TOTAL tasks completed ($COMPLETION_RATE%)"

# Archive existing weekly review if it exists
WEEKLY_REVIEW_FILE="$VAULT_DIR/Weekly-Covey-Review.md"
ARCHIVED_DIR="$VAULT_DIR/Archived"

if [ -f "$WEEKLY_REVIEW_FILE" ]; then
    mkdir -p "$ARCHIVED_DIR"
    mv "$WEEKLY_REVIEW_FILE" "$ARCHIVED_DIR/Weekly-Covey-Review-${TIMESTAMP}.md"
    log "Archived previous weekly review to $ARCHIVED_DIR/Weekly-Covey-Review-${TIMESTAMP}.md"
fi

# ==============================================================================
# MULTI-STEP COVEY WEEKLY REVIEW FLOW WITH CONTINUED CONTEXT
# ==============================================================================

# Step 1: Load all data and generate pre-review questions
log "Step 1: Loading data and generating pre-review questions"
cat > /tmp/weekly_flow_initial.txt << EOF
COVEY WEEKLY REVIEW MULTI-STEP PROCESS - STEP 1: PRE-REVIEW QUESTIONS

I'm starting a multi-step weekly review process that will use --continue to maintain context. 

**FIRST, LOAD ALL DATA SOURCES:**
- Current month's comprehensive analysis: $CURRENT_MONTH_ANALYSIS
- Current ADHD tasks: $ADHD_TASKS_FILE 
- Previous week's Priority Management file: $PRIORITY_FILE (if exists)
- Recent daily summary files in $VAULT_DIR (files named 2025-*.md from this week)
- All Topics/*.md files for context
- Mission statement: $MISSION_FILE
- Biography data: $BIOGRAPHY_FILE

**CURRENT METRICS:**
- Review Date: ${DATE_READABLE}
- Week of: ${WEEK_OF}
- Task Completion Rate: ${COMPLETION_RATE}% (${CHECKBOX_COMPLETED}/${CHECKBOX_TOTAL})
- Total Biography Questions: $QUESTION_COUNT responses

**NOW GENERATE PRE-REVIEW QUESTIONS:**

Based on the data you just loaded, generate 3-5 targeted questions to fill knowledge gaps before creating the weekly review.

**REQUIREMENTS:**
1. **Focus on gaps in current data** - What's missing for a complete weekly review?
2. **Target low completion areas** - Areas with <50% task completion need deeper insight
3. **Binary format** - Questions must be answerable with two button options
4. **Actionable insight** - Questions should reveal info that improves next week's planning

**QUESTION FORMAT:**
Question text? → Button options: "ClearOption1/ClearOption2"

**BUTTON LABEL REQUIREMENTS:**
- Labels must be descriptive and clear (not just "Yes/No" or "High/Low")
- Examples: "Obstacle-Identified/Still-Unclear", "Morning-Works/Morning-Fails", "Anxious-Always/Manageable-Sometimes"
- Each label should clearly indicate what the user is confirming

**AREAS TO PROBE:**
- Why job applications are at low completion (what's the obstacle?)
- Morning routine struggles (what makes wake-up hard?)
- Interview anxiety patterns (what specifically causes stress?)
- Daily planning effectiveness (what derails the schedule?)
- Support system utilization (how well is support being used?)

**IF NEW TOPIC AREAS EMERGE:**
- Use $SCRIPTS_DIR/utils/topic-manager.sh create "Topic Name" to create new topic pages
- Focus on areas that would benefit from 10+ focused questions
- Only create topics that genuinely add value beyond existing coverage

Create 3-5 specific questions based on the data patterns. Format as:

**EXAMPLES OF GOOD QUESTIONS WITH CLEAR BUTTONS:**
1. "Is the main obstacle to job applications emotional resistance or logistical barriers?" → Button options: "Emotional-Resistance/Logistical-Barriers"
2. "Does your 6:30 AM wake-up fail due to late sleep or morning resistance?" → Button options: "Sleep-Too-Late/Morning-Resistance"  
3. "Is interview anxiety worse during prep time or during actual interviews?" → Button options: "Prep-Anxiety/Interview-Anxiety"

**YOUR 3-5 QUESTIONS:**
1. Question text? → Button options: "ClearOption1/ClearOption2"
2. Question text? → Button options: "ClearOption1/ClearOption2"
etc.
EOF

# Execute initial step and capture output
CLAUDE_OUTPUT="/tmp/claude_pre_review_output_$(date +%s).txt"
log "Loading all data and generating pre-review questions"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" < /tmp/weekly_flow_initial.txt > "$CLAUDE_OUTPUT"

# Clean up temp file
rm -f /tmp/weekly_flow_initial.txt

# Step 2: Extract and present pre-review questions
log "Step 2: Extracting and presenting pre-review questions"
if [ -f "$CLAUDE_OUTPUT" ] && [ -s "$CLAUDE_OUTPUT" ]; then
    log "Claude output captured, extracting questions..."
    
    # Check if questions were generated
    QUESTION_COUNT=$(grep -c "^[0-9]\+\." "$CLAUDE_OUTPUT" | head -1 || echo 0)
    log "Found $QUESTION_COUNT pre-review questions in Claude output"
    
    if [ "$QUESTION_COUNT" -gt 0 ]; then
        echo ""
        echo "🔍 PRE-REVIEW PHASE: $QUESTION_COUNT questions identified"
        echo "⏸️  PAUSING weekly review for targeted questions..."
        echo ""
        
        # Present pre-review questions and WAIT for completion
        log "Presenting $QUESTION_COUNT pre-review questions to user - PAUSING for responses"
        "$SCRIPTS_DIR/utils/pre-review-questioner.sh" "$CLAUDE_OUTPUT"
        
        echo ""
        echo "✅ Pre-review questions completed"
        echo "▶️  Continuing with weekly review generation..."
        echo ""
        
        log "Pre-review questions completed, continuing with weekly review"
    else
        log "No pre-review questions found in Claude output, continuing without questions"
        echo "ℹ️  No pre-review questions needed - proceeding to weekly review"
    fi
else
    log "No Claude output captured, skipping pre-review questions"
fi

# Clean up Claude output file
rm -f "$CLAUDE_OUTPUT"

# Step 3: Generate weekly review with all context
log "Step 3: Generating weekly Covey review with full context"
cat > /tmp/weekly_flow_review.txt << EOF
STEP 2: GENERATE WEEKLY COVEY REVIEW

Now create the comprehensive weekly review using all loaded data and any pre-review question insights.

Create 'Weekly-Covey-Review.md' in $VAULT_DIR with:

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
- Integration of any pre-review question insights

### Challenge Areas Identified  
- Tasks or areas with low completion rates (specific data from completion analysis)
- Obstacles that emerged this week
- Gaps between intentions and actions

### Next Week Focus
- 3 specific actions for the coming week (vital few approach)
- Priorities based on monthly plan + this week's learnings
- Adjustments to approach based on what's working/not working

**STYLE NOTES:**
- Keep it concise (2-3 pages max vs comprehensive monthly analysis)
- Focus on actionable insights for next week
- Reference specific items from monthly plan
- Use Covey principles but don't repeat full framework
- Include internal links to relevant topics

This is a progress review informed by comprehensive data loading.
EOF

# Continue with weekly review generation
log "Generating weekly review with continued context"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue < /tmp/weekly_flow_review.txt

# Clean up temp file
rm -f /tmp/weekly_flow_review.txt

# Trigger follow-up activities if the review was generated successfully
if [ -f "$WEEKLY_REVIEW_FILE" ]; then
    log "Weekly review generated successfully, triggering follow-up activities"
    
    # Small delay to ensure file is fully written
    sleep 2
    
    # Archive existing Priority Management file if it exists
    PRIORITY_FILE="$VAULT_DIR/Priority-Management.md"
    ARCHIVED_DIR="$VAULT_DIR/Archived"
    
    if [ -f "$PRIORITY_FILE" ]; then
        mkdir -p "$ARCHIVED_DIR"
        mv "$PRIORITY_FILE" "$ARCHIVED_DIR/Priority-Management-${TIMESTAMP}.md"
        log "Archived previous priority file to $ARCHIVED_DIR/Priority-Management-${TIMESTAMP}.md"
    fi
    
    # Step 4: Generate priorities file using --continue to maintain context
    log "Step 4: Generating priority management file using continued Claude context"
    
    cat > /tmp/priority_continuation_prompt.txt << EOF
STEP 3: GENERATE PRIORITY MANAGEMENT FILE

Now create a comprehensive Priority Management file for the upcoming week using all the context from our data loading and weekly review.

Create 'Priority-Management.md' in $VAULT_DIR based on the template at $SCRIPTS_DIR/templates/Priority-Management.md.

**IMPORTANT INSTRUCTIONS:**

1. **Use the Essentialism 90% Rule** to identify the vital few (max 3) priorities from all our analysis
2. **Populate the Four Quadrants** with specific items from the loaded data:
   - Q1: Any urgent items identified in the review
   - Q2 (Essential Zone): The 3 vital few priorities with specific time blocks
   - Q3: Items to delegate/eliminate based on low completion rates
   - Q4: Time wasters identified in the progress assessment

3. **Fill in the Three-Phase Essentialism Framework**:
   - Explore/Evaluate: Based on current life focus and mission alignment
   - Eliminate: Specific commitments/habits to stop based on review data
   - Execute: Small wins and buffer strategies for the vital few

4. **Include Specific Data** from this week's analysis:
   - Task completion rates: ${COMPLETION_RATE}% (${CHECKBOX_COMPLETED}/${CHECKBOX_TOTAL})
   - Areas needing attention (those with <50% completion)
   - Progress patterns identified in all the loaded data

5. **Schedule Deep Work Blocks** for the vital few across the week
6. **Set up decision filters** based on current mission and effectiveness gaps

Make it actionable and specific to all the insights from our comprehensive data analysis, not generic.

Week of: ${WEEK_OF}
Date: ${DATE_READABLE}
EOF

    # Continue the Claude conversation with priority generation
    "$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue < /tmp/priority_continuation_prompt.txt
    
    # Clean up temp file
    rm -f /tmp/priority_continuation_prompt.txt
    
    # Step 5: Add follow-up questions to topic files (no user interaction needed)
    log "Step 5: Adding follow-up questions to relevant topic files"
    
    cat > /tmp/topic_questions_prompt.txt << EOF
STEP 4: ADD FOLLOW-UP QUESTIONS TO TOPIC FILES

Based on all our analysis, generate 2-3 follow-up questions for each relevant topic area that needs deeper exploration over the coming week.

**REQUIREMENTS:**
- Questions should be yes/no format for future notification responses
- Focus on areas identified as needing improvement in our analysis
- Use the topic-manager.sh utility to properly add questions
- Format: Use $SCRIPTS_DIR/utils/topic-manager.sh add-question "Topic Name" "question text"

**PROCESS:**
1. For each relevant topic area (Career Transition, Personal Effectiveness, Job Search Strategy, Interview Performance, etc.):
2. Generate 2-3 specific questions based on gaps identified in our analysis
3. Use topic-manager.sh to add each question properly

**EXAMPLE COMMANDS TO EXECUTE:**
- $SCRIPTS_DIR/utils/topic-manager.sh add-question "Career Transition" "Have you identified the specific obstacle preventing daily job applications?"
- $SCRIPTS_DIR/utils/topic-manager.sh add-question "Personal Effectiveness" "Does your current morning routine support your 6:30 AM wake-up goal?"
- $SCRIPTS_DIR/utils/topic-manager.sh add-question "Interview Performance" "Have you practiced the specific anxiety management technique that works best for you?"

**FOCUS AREAS FROM ANALYSIS:**
- Job search consistency (17% completion rate needs investigation)
- Morning routine discipline (29% completion needs support)
- Interview anxiety management (specific techniques needed)
- Daily planning effectiveness (what derails the schedule?)
- Support system utilization (how to better use girlfriend's support?)

Generate the specific add-question commands and execute them using topic-manager.sh.
EOF

    # Continue with topic question generation
    "$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue < /tmp/topic_questions_prompt.txt
    
    # Clean up temp file
    rm -f /tmp/topic_questions_prompt.txt
    
    log "All follow-up activities completed successfully"
fi

log "Weekly Covey progress review and priority generation completed"