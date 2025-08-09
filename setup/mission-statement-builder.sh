#!/bin/bash

# Mission Statement Builder
# Uses Claude to analyze existing Q&A responses and guide mission statement creation
# Creates comprehensive Mission Statement.md based on user's biography data

# Auto-load configuration and logging
source "$(dirname "$0")/../utils/auto-config.sh"
source "$(dirname "$0")/../utils/logger.sh"

# Set environment for proper operations
export DISPLAY="${DISPLAY:-:1}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

echo "🎯 Mission Statement Builder"
echo "Creating your personal mission statement based on your Q&A responses..."

log_start "Mission statement creation process"

# Check if we have enough data
if [[ ! -f "$BIOGRAPHY_FILE" ]] && [[ ! -d "$TOPICS_DIR" ]]; then
    echo "❌ No biography data found. Please run bootstrap-questions.sh first."
    exit 1
fi

# Mission statement creation prompt
MISSION_STATEMENT_PROMPT="PERSONAL MISSION STATEMENT CREATION

TASK: Analyze all available biography Q&A data and guide the user through creating a comprehensive personal mission statement.

STEP 1 - CONTEXT ANALYSIS:
1. Read all available biography data from $BIOGRAPHY_FILE
2. Scan all topic files in $TOPICS_DIR for answered questions (✅ status)
3. Analyze patterns in responses to understand:
   - Core values and priorities
   - Life goals and aspirations
   - Current challenges and focus areas
   - Relationship priorities
   - Professional objectives
   - Personal growth areas

STEP 2 - MISSION STATEMENT FRAMEWORK:
Create a mission statement following Stephen Covey's approach with these components:

**Personal Mission Statement Structure:**
1. **Core Values** - What principles guide your decisions?
2. **Life Roles** - Key roles you play (family member, professional, friend, etc.)
3. **Primary Purposes** - What you want to accomplish in each role
4. **Vision Statement** - Where you see yourself in 5-10 years
5. **Daily Principles** - How these translate to daily actions

STEP 3 - INTERACTIVE CREATION:
Based on the Q&A analysis, present the user with:
1. **Identified themes** from their responses
2. **Proposed mission statement draft** based on their answers
3. **Interactive refinement** questions to personalize and improve
4. **Values clarification** questions for areas needing more detail

STEP 4 - MISSION STATEMENT GENERATION:
Create a comprehensive Mission Statement.md file with:
- Complete personal mission statement
- Core values list with explanations
- Life roles and purposes
- Vision statement
- Daily principles for living the mission
- Links to relevant topic areas: [[Career Transition]], [[Personal Effectiveness]], etc.
- Proper Obsidian formatting with tags: #mission #values #goals #purpose

STEP 5 - VALIDATION & FEEDBACK:
Present the complete mission statement and ask for final validation/modifications.

IMPORTANT: Make this conversational and interactive. Don't just generate a mission statement - guide the user through understanding their own values and purposes based on what they've already shared.

Begin by analyzing all available Q&A data and presenting your findings."

log_info "Analyzing biography data for mission statement creation"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$MISSION_STATEMENT_PROMPT"

log_end "Mission statement creation"

echo ""
echo "✅ Mission Statement created!"
echo ""
echo "Your mission statement has been saved to: $MISSION_FILE"
echo ""
echo "Next steps:"
echo "1. Review your mission statement in Obsidian"
echo "2. Set up automated cron jobs: crontab -e (see README.md for schedule)"
echo "3. The system will now use your mission to prioritize questions and tasks"
echo ""
echo "🎉 Biography system setup complete! The system will now:"
echo "   • Generate questions aligned with your mission and priorities"
echo "   • Create ADHD-friendly task lists based on your goals"  
echo "   • Track progress toward your stated purposes"
echo "   • Provide Covey 7 Habits analysis aligned with your values"