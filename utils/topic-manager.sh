#!/bin/bash

# Topic Manager - Intelligent Claude-powered topic organization with Obsidian integration
# Replaces complex bash logic with Claude's intelligence for smart topic management

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Set environment for proper operations
export DISPLAY="${DISPLAY:-:1}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$TOPIC_MANAGER_LOG"
}

# Main intelligent topic management function
main() {
    local command="$1"
    local arg1="$2" 
    local arg2="$3"
    local arg3="$4"
    
    # Validate command
    if [ -z "$command" ]; then
        echo "Usage: $0 {create|add-question|route-question|update-status|consolidate}"
        echo "  create <topic_name>                 - Create new topic page"
        echo "  add-question <topic_name> <question> - Add question to topic"
        echo "  route-question <question>           - Determine optimal topic for question"
        echo "  update-status <question> <status> [answer] - Update question status"
        echo "  consolidate [topic_name]            - Merge similar answered questions into insights"
        exit 1
    fi

    log "Starting intelligent topic management: $command $arg1"

    # Comprehensive Claude prompt for intelligent topic management
    TOPIC_MANAGEMENT_PROMPT="Intelligent topic management task: $command

SYSTEM INFO:
- OS: $(uname -s) $(uname -r)
- Desktop: ${XDG_CURRENT_DESKTOP:-Unknown}
- Obsidian Vault: $VAULT_DIR
- Topics Directory: $TOPICS_DIR
- Biography File: $BIOGRAPHY_FILE

COMMAND DETAILS:
- Task: $command
- Arguments: '$arg1' '$arg2' '$arg3'

CONTEXT ANALYSIS:
1. Scan all existing topic files in $TOPICS_DIR to understand current organization
2. Analyze current Obsidian tag usage patterns across topics
3. Review question themes and identify topic relationships
4. Assess topic health: activity levels, completion rates, recent patterns

TASK EXECUTION:
Execute the requested command with intelligence:

FOR 'create' COMMAND:
- Create new topic page with proper Obsidian structure
- Add relevant #tags based on topic name and purpose
- Include [[Topic Links]] to related existing topics
- Add analytics section for future tracking
- Link from Biography.md if appropriate

FOR 'add-question' COMMAND:
- Add question to specified topic with ❌ status
- Ensure proper markdown formatting
- Add relevant #tags if question introduces new themes
- Create [[Links]] to related topics if applicable
- Update topic analytics if patterns emerge

FOR 'route-question' COMMAND:
- Analyze question content and themes
- Compare against existing topic purposes and content
- Return the BEST existing topic name, or suggest new topic if needed
- Consider topic consolidation opportunities
- Output ONLY the topic name

FOR 'update-status' COMMAND:
- Find question across all topic files
- Update status with proper markdown formatting
- Add timestamp and answer if provided
- Update topic analytics with new completion data
- Add cross-references if answer reveals connections

FOR 'consolidate' COMMAND:
- Analyze all answered questions (✅ status) in specified topic (or all topics if none specified)
- Focus on ONLY the biggest priority clusters - identify the 2-3 most important themes with multiple similar questions
- Select only the highest-impact redundant questions that appear frequently or relate to core priorities
- Combine ONLY these priority clusters into single, comprehensive and information-rich Q&As
- Leave standalone questions and minor themes untouched - only consolidate where there's clear redundancy
- Replace multiple narrow priority questions with broader, more valuable consolidated versions
- Synthesize answers from similar high-priority questions into complete, actionable responses
- REMOVE only the consolidated redundant questions to reduce noise while preserving unique content
- Keep consolidation targeted and selective - quality over quantity
- Archive removed questions in backup/log if tracking is needed

OBSIDIAN INTEGRATION FEATURES:
- **Auto-tagging**: Add relevant #tags like #career/transition #productivity/morning #goals/financial
- **Smart linking**: Create [[Topic Name]] links between related topics
- **Cross-references**: Link related questions with [[Topic#Question]] format when appropriate
- **Hierarchical tags**: Use tag hierarchies like #career/interview #productivity/focus
- **Metadata**: Include topic creation dates, last updated, question counts

TOPIC ORGANIZATION PRINCIPLES:
- Prefer routing to existing relevant topics over creating new ones
- Create new topics only for genuinely distinct areas
- Maintain clean, discoverable organization structure
- Use Obsidian features to enhance navigation and discovery
- Keep topic names concise but descriptive (2-3 words)
- Consider current ADHD task priorities and career transition focus

Execute the command and provide clear, actionable results."

    log "Executing intelligent topic management with Claude"
    "$SCRIPTS_DIR/utils/claude-wrapper.sh" "$TOPIC_MANAGEMENT_PROMPT"
    
    log "Topic management completed: $command"
}

# Execute main function with all arguments
main "$@"