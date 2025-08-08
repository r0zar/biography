#!/bin/bash

# Biography Question Generator
# Uses Claude to generate intelligent, contextual biography questions
# Extracted from tasks/biography-questions.sh for better separation of concerns

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$BIOGRAPHY_LOG"
}

log "Starting intelligent biography question generation"

# Generate up to 3 prioritized questions using Claude's intelligence with --continue
echo "📖 Generating biography questions..."

# Initial prompt to load all context
INITIAL_PROMPT="BIOGRAPHY Q&A SESSION - GENERATE 3 PRIORITIZED QUESTIONS

I need to generate 3 high-priority biography questions in sequence using -c for efficiency.

**FIRST, LOAD ALL CONTEXT:**
1. Read Priority Management file at $VAULT_DIR/Priority-Management.md to understand current vital few priorities
2. Read Covey analysis at $COVEY_FILE to understand effectiveness gaps and areas needing attention  
3. Read mission statement at $MISSION_FILE to understand core values and life purpose
4. Scan ALL topic files in $VAULT_DIR/Topics/ to see:
   - Existing unanswered questions (marked with ❌) - AVOID generating similar questions
   - Recently answered questions (marked with ✅) - understand what's already been explored
   - Note any recurring themes or duplicate question patterns to AVOID

**NOW GENERATE QUESTION 1:**
Based on ALL this context, identify the SINGLE most important question to ask right now that will:
- Address the highest priority areas from Priority Management
- Target effectiveness gaps with low completion rates
- Align with mission statement values (family security, career transition urgency)
- Fill critical knowledge gaps for current life situation
- BE COMPLETELY DIFFERENT from existing questions (avoid duplicates or near-duplicates)
- Explore NEW angles not already covered by recent questions

Then:
1. Use $SCRIPTS_DIR/utils/topic-manager.sh route-question \"[your question]\" to determine the best topic file
2. Add the question using topic-manager.sh add-question \"Topic Name\" \"question text\"
3. Format questions according to the template at $QUESTION_FORMAT_TEMPLATE
4. Present the question immediately using available dialog libraries (zenity, kdialog, etc.)

Focus on the most URGENT and IMPORTANT areas based on Priority Management vital few."

log "Loading context and generating question 1 of 3"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$INITIAL_PROMPT"

# Continue with question 2
log "Generating question 2 of 3 using continued context"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" -c "GENERATE QUESTION 2:

Now generate the SECOND most important question, considering:
- What was just asked in question 1 - AVOID similar themes
- The remaining high-priority areas from Priority Management  
- Different topic areas to get broader coverage
- COMPLETELY DIFFERENT angle from question 1 and all existing questions
- Same process: route, add, format with custom labels, and present via dialog"

# Continue with question 3  
log "Generating question 3 of 3 using continued context"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" -c "GENERATE QUESTION 3:

Generate the THIRD most important question, considering:
- Questions 1 and 2 that were just asked - AVOID similar themes entirely
- Remaining priority areas to ensure comprehensive coverage
- Focus on any critical gaps not yet addressed  
- MUST be completely unique - different topic area if possible
- Same process: route, add, format with custom labels, and present via dialog"

log "Biography question generation completed"