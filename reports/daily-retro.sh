#!/bin/bash

# Daily Retrospective Generator - Unified report system
# Replaces daily-summary.py, daily-summary-wrapper.sh, extract-new-topics.sh, 
# extract-qa-data.py, and command-extractor.sh with single comprehensive Claude prompt

# Auto-load configuration and logging
source "$(dirname "$0")/../utils/auto-config.sh"
source "$(dirname "$0")/../utils/logger.sh"

# Set GUI environment variables for proper dialog display
export DISPLAY="${DISPLAY:-:1}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# Show usage information
show_usage() {
    echo "Usage: $0 [--picard] {create|organize-topics}"
    echo ""
    echo "Options:"
    echo "  --picard        Use Captain Picard style for narrative (Captain's Log format)"
    echo ""
    echo "Commands:"
    echo "  create          Generate daily summary from today's Q&A data"
    echo "  organize-topics Organize and optimize topic system (questions, consolidation, research)"
    echo ""
    echo "Examples:"
    echo "  $0 create              # Standard personal narrative style"
    echo "  $0 --picard create     # Captain Picard Captain's Log style"
    echo "  $0 organize-topics"
    exit 1
}

# Handle create command - generate daily summary
handle_create() {
    local use_picard_style="$1"
    local date_today=$(date '+%Y-%m-%d')
    local daily_file="$VAULT_DIR/$date_today.md"
    
    log_start "Daily summary creation for $date_today"
    
    # Archive yesterday's daily retrospective if it exists
    local yesterday=$(date -d "yesterday" '+%Y-%m-%d')
    local yesterday_file="$VAULT_DIR/$yesterday.md"
    local archived_dir="$VAULT_DIR/Archived"
    
    if [[ -f "$yesterday_file" ]]; then
        mkdir -p "$archived_dir"
        if mv "$yesterday_file" "$archived_dir/"; then
            log_info "Archived yesterday's retrospective: $yesterday.md → Archived/"
        else
            log_warn "Failed to archive yesterday's retrospective: $yesterday.md"
        fi
    fi
    
    # Build style-specific instructions
    local style_instructions=""
    if [[ "$use_picard_style" == "true" ]]; then
        style_instructions="   - Follow the Captain Picard style guide at: $SCRIPTS_DIR/prompts/picard-daily-summary.md
   - Write 200-300 word Captain's Log entry about the person's day
   - Begin with \"Personal Log, Stardate $date_today\"
   - Use Picard's philosophical, reflective tone"
    else
        style_instructions="   - Write 200-300 word third-person personal narrative about the person's day
   - Focus on who they are, current situation, challenges, values
   - Use thoughtful, introspective tone without the Captain's Log format"
    fi

    # Build comprehensive prompt for Claude
    local DAILY_PROMPT="TASK: Create comprehensive daily summary

SYSTEM INFO:
- Date: $date_today
- Vault Directory: $VAULT_DIR
- Topics Directory: $VAULT_DIR/Topics
- Biography File: $VAULT_DIR/Biography.md
- Mission Statement: $VAULT_DIR/Mission Statement.md
- Priority Management: $VAULT_DIR/Priority-Management.md
- Monthly Planning: $VAULT_DIR/Monthly Planning.md
- Weekly Retro: $VAULT_DIR/Weekly Retro.md  
- Weekly Planning: $VAULT_DIR/Weekly Planning.md
- Daily Planning: $VAULT_DIR/Daily Planning.md
- Output File: $daily_file

CONTEXT FOR SUMMARY:
- Review Mission Statement.md for core values and life direction alignment
- Check Priority-Management.md for current priority framework and focus areas
- Examine Monthly Planning.md for recent effectiveness insights and development goals
- Review Weekly Retro.md and Weekly Planning.md for progress tracking and weekly patterns
- Check Daily Planning.md for current priorities and task completion status
- Examine checkbox status in task lists (✅ completed, ❌ not done) to assess daily progress
- Analyze completion patterns in task files to identify productivity trends
- Examine past daily summary files ($VAULT_DIR/2025-*.md) to understand progression over time
- Look for archived daily planning files to track priority evolution and completion patterns
- Compare today's activities with recent trends and identify growth areas or recurring challenges
- Use this longitudinal context to provide meaningful insights about daily progression

INSTRUCTIONS:
1. ANALYZE TODAY'S Q&A DATA AND TASK COMPLETION:
   - Scan all topic files in $VAULT_DIR/Topics for questions answered today ($date_today)
   - Look for pattern: ✅ [question] **Answer:** [answer] *(answered $date_today...)*
   - Count total questions answered and extract question-answer pairs for narrative generation
   - Analyze checkbox status in Daily Planning.md and other task lists:
     * Count ✅ (completed) vs ❌ (incomplete) tasks
     * Identify which types of tasks are being completed vs avoided
     * Note task completion rate and patterns compared to previous days

2. GENERATE PERSONAL NARRATIVE:
$style_instructions
   - Include insights from reviewing past daily summaries and task progression
   - Note patterns, improvements, or recurring challenges compared to recent days
   - Reference specific progress or setbacks in the context of longer-term development

3. CREATE DAILY SUMMARY FILE:
   - Write to: $daily_file
   - Use format below
   - Include navigation links to yesterday/tomorrow dates
   - Add appropriate tags and metadata

4. ORGANIZE TOPICS (if needed):
   - Review all topic files and assess organization needs
   - Consider a mix of operations as appropriate:
     * Generate new questions for underdeveloped topics
     * Consolidate similar/redundant topics using topic-manager.sh consolidate
     * Create new topic pages for emerging themes from Covey analysis
     * Research current best practices to enhance topic depth
   - Focus on improving overall topic system value and usability

FILE FORMAT TO CREATE:
---
# Daily Portrait - [Month Day, Year]

*A personal narrative based on today's biography questions*

---

[Generated narrative here]

---

**Questions explored today:** [count]
*Generated on $date_today at [time]*

## Today's Q&A Summary

---

[[Biography]] | [[$(date -d yesterday '+%Y-%m-%d')]] | [[$(date -d tomorrow '+%Y-%m-%d')]]

#daily #portrait #biography #$(date '+%Y') #$(date '+%B' | tr '[:upper:]' '[:lower:]')
---

EXECUTION REQUIREMENTS:
- If no questions answered today, create simple summary noting this
- Handle file reading errors gracefully
- Execute any topic-manager commands for organization tasks
- Log progress and results
- Output the final file path when complete
- Display summary dialog: zenity --info --title=\\\"Daily Summary Complete\\\" --text=\\\"Created Captain's Log for $date_today\\\\n\\\\nQuestions answered: [X]\\\\nTopics engaged: [list]\\\\nNarrative: [brief description]\\\"

Complete all operations and provide final status."
    
    log_info "Executing daily summary generation with Claude"
    
    if "$SCRIPTS_DIR/utils/claude-wrapper.sh" "$DAILY_PROMPT"; then
        log_info "Daily summary generation completed successfully"
        echo "$daily_file"
    else
        log_error "Daily summary generation failed"
        exit 1
    fi
}

# Handle organize-topics command  
handle_organize_topics() {
    log_start "Topic organization and optimization"
    
    local ORGANIZE_PROMPT="TASK: Organize and optimize topic system

SYSTEM INFO:
- Vault Directory: $VAULT_DIR
- Topics Directory: $VAULT_DIR/Topics
- Biography File: $VAULT_DIR/Biography.md

INSTRUCTIONS:
1. ASSESS TOPIC SYSTEM:
   - Review all existing topic files in $VAULT_DIR/Topics
   - Analyze topic health: completion rates, activity levels, question quality
   - Identify organizational opportunities and inefficiencies

2. DETERMINE OPTIMIZATION STRATEGY:
   - For underdeveloped topics: Generate new relevant questions
   - For similar/overlapping topics: Consider consolidation via topic-manager.sh consolidate
   - For emerging themes: Create new focused topic pages
   - For stale topics: Research current best practices to enhance depth and relevance

3. EXECUTE OPTIMIZATION ACTIONS:
   - Generate questions: topic-manager.sh add-question \"[Topic]\" \"[Question]?\"
   - Consolidate topics: topic-manager.sh consolidate \"[Topic Name]\"
   - Create new topics: topic-manager.sh create \"[Topic Name]\"
   - Research integration: Use web search to enhance topic depth with current information

4. REPORT RESULTS:
   - Log all optimization actions taken
   - Report improvements made to topic organization
   - Provide summary of questions added, topics consolidated, or new topics created

5. DISPLAY ORGANIZATION SUMMARY:
   - Use zenity --info dialog to show detailed summary of topic optimizations made
   - Include specific details: which topics were modified, questions added, consolidations performed
   - Format for readability with line breaks and clear sections
   - Example: zenity --info --title=\"Topic Organization Complete\" --text=\"QUESTIONS ADDED:\\n• Career Transition: 3 questions\\n• Personal Effectiveness: 2 questions\\n\\nTOPICS CONSOLIDATED:\\n• Merged Morning Routine into Daily Habits\\n\\nNEW TOPICS CREATED:\\n• Interview Preparation\\n\\nTotal: 5 questions added, 1 consolidation, 1 new topic\"

Execute all topic management commands as appropriate.
Focus on improving overall system value and usability.
Provide comprehensive status report when complete."
    
    log_info "Executing topic organization with Claude"
    
    if "$SCRIPTS_DIR/utils/claude-wrapper.sh" "$ORGANIZE_PROMPT"; then
        log_info "Topic organization completed successfully"
    else
        log_error "Topic organization failed"
        exit 1
    fi
}

# Main function
main() {
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOGS_DIR/daily-summary.log")"
    
    local use_picard_style="false"
    local command=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --picard)
                use_picard_style="true"
                shift
                ;;
            create)
                command="create"
                shift
                break
                ;;
            organize-topics)
                command="organize-topics"
                shift
                break
                ;;
            *)
                show_usage
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        create)
            handle_create "$use_picard_style"
            ;;
        organize-topics)
            handle_organize_topics
            ;;
        *)
            show_usage
            ;;
    esac
    
    log_end "Daily summary operation"
}

# Execute main function with all arguments
main "$@"