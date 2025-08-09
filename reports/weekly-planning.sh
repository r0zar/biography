#!/bin/bash

# Weekly Planning Generator
# Creates next week focus and planning based on weekly retrospective and Covey analysis

# Auto-load configuration and logging
source "$(dirname "$0")/../utils/auto-config.sh"
source "$(dirname "$0")/../utils/logger.sh"

log_start "Weekly planning analysis"

# Skip if it's the 1st of the month (full analysis day)
if [ $(date +%d) -eq 01 ]; then
    log_info "Skipping weekly planning - monthly comprehensive analysis runs today"
    exit 0
fi

# Generate timestamp for output file
TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
DATE_READABLE=$(date '+%B %d, %Y at %I:%M %p')
WEEK_OF=$(date '+%B %d, %Y')

# Check if current month's Covey analysis exists
CURRENT_MONTH_ANALYSIS="$VAULT_DIR/Monthly Planning.md"
if [ ! -f "$CURRENT_MONTH_ANALYSIS" ]; then
    log_warn "No current month Covey analysis found - cannot perform weekly review"
    exit 1
fi

# Get question count and progress metrics
log_info "Analyzing current progress metrics"
# Get question count from topic files
QUESTION_COUNT=$(find "$VAULT_DIR/Topics" -name "*.md" -exec grep -c "✅.*answered $(date '+%Y-%m-%d')" {} + | awk '{sum+=$1} END {print sum+0}')

# Parse checkbox completion from ADHD tasks and Covey analysis
DAILY_PLANNING_FILE="$VAULT_DIR/Daily Planning.md"
PRIORITY_FILE="$VAULT_DIR/Priority-Management.md"
CHECKBOX_COMPLETED=0
CHECKBOX_TOTAL=0

if [ -f "$DAILY_PLANNING_FILE" ]; then
    CHECKBOX_COMPLETED=$(grep -c "^- \[x\]" "$DAILY_PLANNING_FILE" 2>/dev/null | head -1 || echo "0")
    CHECKBOX_PENDING=$(grep -c "^- \[ \]" "$DAILY_PLANNING_FILE" 2>/dev/null | head -1 || echo "0")
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

log_info "Found $CHECKBOX_COMPLETED/$CHECKBOX_TOTAL tasks completed ($COMPLETION_RATE%)"

# Archive existing weekly review if it exists
WEEKLY_PLANNING_FILE="$VAULT_DIR/Weekly Planning.md"
ARCHIVED_DIR="$VAULT_DIR/Archived"

if [ -f "$WEEKLY_PLANNING_FILE" ]; then
    mkdir -p "$ARCHIVED_DIR"
    mv "$WEEKLY_PLANNING_FILE" "$ARCHIVED_DIR/Weekly Planning-${TIMESTAMP}.md"
    log_info "Archived previous weekly planning to $ARCHIVED_DIR/Weekly Planning-${TIMESTAMP}.md"
fi

# ==============================================================================
# MULTI-STEP COVEY WEEKLY REVIEW FLOW WITH CONTINUED CONTEXT
# ==============================================================================

# Step 1: Load all data and generate pre-review questions
log_info "Step 1: Loading data and generating pre-review questions"
cat > /tmp/weekly_flow_initial.txt << EOF
COVEY WEEKLY REVIEW MULTI-STEP PROCESS - STEP 1: PRE-REVIEW QUESTIONS

I'm starting a multi-step weekly review process that will use --continue to maintain context. 

**FIRST, LOAD ALL DATA SOURCES:**
- Current month's comprehensive analysis: $CURRENT_MONTH_ANALYSIS
- Current Daily Planning: $DAILY_PLANNING_FILE 
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
log_info "Loading all data and generating pre-review questions"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" < /tmp/weekly_flow_initial.txt > "$CLAUDE_OUTPUT"

# Clean up temp file
rm -f /tmp/weekly_flow_initial.txt

# Step 2: Extract and present pre-review questions
log_info "Step 2: Extracting and presenting pre-review questions"
if [ -f "$CLAUDE_OUTPUT" ] && [ -s "$CLAUDE_OUTPUT" ]; then
    log_info "Claude output captured, extracting questions..."
    
    # Check if questions were generated
    QUESTION_COUNT=$(grep -c "^[0-9]\+\." "$CLAUDE_OUTPUT" | head -1 || echo 0)
    log_info "Found $QUESTION_COUNT pre-review questions in Claude output"
    
    if [ "$QUESTION_COUNT" -gt 0 ]; then
        echo ""
        echo "🔍 PRE-REVIEW PHASE: $QUESTION_COUNT questions identified"
        echo "⏸️  PAUSING weekly review for targeted questions..."
        echo ""
        
        # Present pre-review questions and WAIT for completion
        log_info "Presenting $QUESTION_COUNT pre-review questions to user - PAUSING for responses"
        # Extract questions from Claude output and present them using question-manager
        echo "📋 PRE-REVIEW QUESTIONS FROM ANALYSIS:"
        grep "^[0-9]\\+\\." "$CLAUDE_OUTPUT" | head -5
        echo ""
        echo "ℹ️  Review these insights before continuing with weekly planning"
        read -p "Press Enter to continue with weekly planning generation..."
        
        echo ""
        echo "✅ Pre-review questions completed"
        echo "▶️  Continuing with weekly review generation..."
        echo ""
        
        log_info "Pre-review questions completed, continuing with weekly review"
    else
        log_warn "No pre-review questions found in Claude output, continuing without questions"
        echo "ℹ️  No pre-review questions needed - proceeding to weekly review"
    fi
else
    log_warn "No Claude output captured, skipping pre-review questions"
fi

# Clean up Claude output file
rm -f "$CLAUDE_OUTPUT"

# Step 3: Generate weekly review with all context
log_info "Step 3: Generating weekly Covey review with full context"
cat > /tmp/weekly_flow_review.txt << EOF
STEP 2: GREG MCKEOWN ESSENTIALIST WEEKLY PLANNING

Channel Greg McKeown's disciplined pursuit of less to plan next week around the VITAL FEW.

Read the Greg McKeown prompt at: $PROMPTS_DIR/greg-mckeown-essentialist.md

Create 'Weekly Planning.md' in $VAULT_DIR using Essentialism principles:

**THE ESSENTIAL QUESTION:** What is the ONE thing that, if accomplished this week, would make everything else easier or irrelevant?

**MCKEOWN'S 90% RULE FOR PLANNING:**
- Review Date: ${DATE_READABLE} | Week of: ${WEEK_OF}
- Current Completion: ${COMPLETION_RATE}% (${CHECKBOX_COMPLETED}/${CHECKBOX_TOTAL})
- Context: $QUESTION_COUNT biography insights

**ESSENTIAL PLANNING FRAMEWORK:**

### The Vital Few (Maximum 3)
- Apply the 90% rule: Only commitments that score 90+ deserve space
- What are the 2-3 things that will create the highest impact?
- Everything else gets eliminated or delegated

### The One Essential Goal
- The single most important outcome for this week
- The thing that, if achieved, makes the biggest difference to your mission
- Must align with your deepest values and current priority bottleneck

### Elimination Strategy  
- What will you say NO to this week to protect the essential?
- Which "good" commitments will you eliminate for "great" ones?
- How will you create buffer and space around your vital few?

### Execution Design
- Minimum viable approach to maximum impact
- Time blocks for the essential (not the urgent)
- Systems to protect focus and eliminate distractions

**ESSENTIALISM VOICE:** Write with Greg McKeown's clarity and conviction. Less planning, more deciding. Focus on disciplined choices that create space for breakthrough.

Remember: The goal isn't to do more things - it's to do the right things with excellence.
EOF

# Continue with weekly review generation
log_info "Generating weekly planning with continued context"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue < /tmp/weekly_flow_review.txt

# Clean up temp file
rm -f /tmp/weekly_flow_review.txt

# Trigger follow-up activities if the planning was generated successfully
if [ -f "$WEEKLY_PLANNING_FILE" ]; then
    log_info "Weekly planning generated successfully, triggering follow-up activities"
    
    # Small delay to ensure file is fully written
    sleep 2
    
    # Archive existing Priority Management file if it exists
    PRIORITY_FILE="$VAULT_DIR/Priority-Management.md"
    ARCHIVED_DIR="$VAULT_DIR/Archived"
    
    if [ -f "$PRIORITY_FILE" ]; then
        mkdir -p "$ARCHIVED_DIR"
        mv "$PRIORITY_FILE" "$ARCHIVED_DIR/Priority-Management-${TIMESTAMP}.md"
        log_info "Archived previous priority file to $ARCHIVED_DIR/Priority-Management-${TIMESTAMP}.md"
    fi
    
    # Step 4: Generate priorities file using --continue to maintain context
    log_info "Step 4: Generating priority management file using continued Claude context"
    
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
    log_info "Step 5: Adding follow-up questions to relevant topic files"
    
    cat > /tmp/topic_questions_prompt.txt << EOF
STEP 4: ADD FOLLOW-UP QUESTIONS TO TOPIC FILES

Based on all our analysis, generate 2-3 follow-up questions for each relevant topic area that needs deeper exploration over the coming week.

**REQUIREMENTS:**
- Questions should be yes/no format for future notification responses
- For "this or that" questions with two specific options, use custom button format: "Question text? [Yes=Option1|No=Option2]"
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
- $SCRIPTS_DIR/utils/topic-manager.sh add-question "Interview Performance" "Is your interview anxiety worse during prep time or during actual interviews? [Yes=Prep-Anxiety|No=Interview-Anxiety]"

**FOCUS AREAS FROM ANALYSIS:**
- Job search consistency (17% completion rate needs investigation)
- Morning routine discipline (29% completion needs support)
- Interview anxiety management (specific techniques needed)
- Daily planning effectiveness (what derails the schedule?)
- Support system utilization (how to better use girlfriend's support?)

**OUTPUT THE ACTUAL COMMANDS TO EXECUTE:**

After your analysis, output the specific commands exactly as they should be executed, one per line:

$SCRIPTS_DIR/utils/topic-manager.sh add-question "Topic Name" "Question text?"
$SCRIPTS_DIR/utils/topic-manager.sh add-question "Topic Name" "Question text?"
(etc.)

**IMPORTANT:** Do not just describe what you would add - output the actual executable commands that will add the questions to the topic files.
EOF

    # Continue with topic question generation and capture output
    CLAUDE_TOPIC_OUTPUT="/tmp/claude_topic_output_$(date +%s).txt"
    "$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue < /tmp/topic_questions_prompt.txt > "$CLAUDE_TOPIC_OUTPUT"
    
    # Extract and execute topic-manager commands from Claude output
    if [ -f "$CLAUDE_TOPIC_OUTPUT" ] && [ -s "$CLAUDE_TOPIC_OUTPUT" ]; then
        log_info "Extracting and executing topic-manager commands"
        # Extract lines that contain topic-manager.sh commands
        grep "$SCRIPTS_DIR/utils/topic-manager.sh" "$CLAUDE_TOPIC_OUTPUT" | while read -r cmd; do
            log_info "Executing: $cmd"
            eval "$cmd"
        done
    else
        log_warn "No Claude output captured for command extraction"
    fi
    
    # Clean up temp files
    rm -f /tmp/topic_questions_prompt.txt
    rm -f "$CLAUDE_TOPIC_OUTPUT"
    
    log_info "All follow-up activities completed successfully"
fi

log_end "Weekly Covey progress review and priority generation"