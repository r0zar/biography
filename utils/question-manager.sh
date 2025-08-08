#!/bin/bash

# Question Manager - Unified question presentation and management system
# Consolidates biography-questions.sh, quick-question.sh, pre-review-questioner.sh
# with intelligent context loading and research capabilities

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Set GUI environment variables for proper dialog display
export DISPLAY="${DISPLAY:-:1}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# Initialize context flags
LOAD_BIOGRAPHY=false
LOAD_MISSION=false
LOAD_7HABITS=false
LOAD_ADHD_TASKS=false
LOAD_PRIORITIES=false
LOAD_RECENT_QA=false
LOAD_WEEKLY_REVIEW=false
LOAD_DAILY_SUMMARY=false

# Workflow flags
RESEARCH_ONLINE=false
CONTINUE=false
FAST_MODE=false
LOAD_ALL=false
VERBOSE=false
QUIET=false
DRY_RUN=false

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOGS_DIR/question-manager.log"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [-flags] {ask|pop|generate|help} [arguments]"
    echo ""
    echo "Context Flags (stackable):"
    echo "  -b  biography       Review Biography.md and explore linked topics"
    echo "  -m  mission         Include mission statement"
    echo "  -7  7habits         Include Covey 7 Habits analysis"
    echo "  -a  adhd-tasks      Include ADHD tasks"
    echo "  -p  priorities      Include Priority Management"
    echo "  -q  recent-qa       Include recent Q&As across topics"
    echo "  -w  weekly-review   Include weekly review"
    echo "  -d  daily-summary   Include daily summaries"
    echo ""
    echo "Research & Workflow:"
    echo "  -r  research        Enable online research capability"
    echo "  -c  continue        Continue previous Claude conversation (fast)"
    echo "  -f  fast            Minimal context (fastest)"
    echo "  -A  all             All context sources (excludes research)"
    echo "  -v  verbose         Verbose output"
    echo "  -n  dry-run         Show what would be loaded"
    echo ""
    echo "Commands:"
    echo "  pop [--focus area]                    Get most essential existing question"
    echo "  ask [question|--from-file|--batch]    Present and save question(s)"
    echo "  generate <target> <count>             Create new questions"
    echo "  help [command]                        Show help information"
    echo ""
    echo "Examples:"
    echo "  $0 pop                               # Default: -b7a"
    echo "  $0 -rb7 ask \"Market trends?\"         # Research + context"
    echo "  $0 -rc ask \"Follow-up?\"             # Continue with research"
    echo "  $0 -rA generate --challenges 5       # Research + all context"
    echo ""
    echo "For detailed help: $0 help [command]"
    exit 1
}

# Parse stackable flags like -b7am
parse_flags() {
    local flags="$1"
    
    # Remove leading dash and process each character
    flags="${flags#-}"
    
    for (( i=0; i<${#flags}; i++ )); do
        case "${flags:$i:1}" in
            b) LOAD_BIOGRAPHY=true ;;
            m) LOAD_MISSION=true ;;
            7) LOAD_7HABITS=true ;;
            a) LOAD_ADHD_TASKS=true ;;
            p) LOAD_PRIORITIES=true ;;
            q) LOAD_RECENT_QA=true ;;
            w) LOAD_WEEKLY_REVIEW=true ;;
            d) LOAD_DAILY_SUMMARY=true ;;
            r) RESEARCH_ONLINE=true ;;
            c) CONTINUE=true ;;
            f) FAST_MODE=true ;;
            A) LOAD_ALL=true ;;
            v) VERBOSE=true ;;
            n) DRY_RUN=true ;;
            *) echo "Unknown flag: ${flags:$i:1}" >&2; show_usage ;;
        esac
    done
}

# Build context prompt based on active flags
build_context_prompt() {
    local context=""
    
    if [[ "$FAST_MODE" == "true" ]]; then
        context+="FAST MODE: Use minimal context for speed.\n\n"
        echo "$context"
        return
    fi
    
    if [[ "$LOAD_ALL" == "true" ]]; then
        LOAD_BIOGRAPHY=true
        LOAD_MISSION=true
        LOAD_7HABITS=true
        LOAD_ADHD_TASKS=true
        LOAD_PRIORITIES=true
        LOAD_RECENT_QA=true
        LOAD_WEEKLY_REVIEW=true
        LOAD_DAILY_SUMMARY=true
        # Note: Does not include research - must be explicitly specified
    fi
    
    context+="CONTEXT LOADING:\n"
    
    if [[ "$LOAD_BIOGRAPHY" == "true" ]]; then
        context+="1. Review Biography.md at $BIOGRAPHY_FILE as the central hub\n"
        context+="2. Follow [[Topic Links]] to explore relevant topic files as needed\n"
        context+="3. Use your judgment to dive into topics most relevant to the current task\n"
    fi
    
    if [[ "$LOAD_MISSION" == "true" ]]; then
        context+="4. Consider mission statement at $MISSION_FILE for priority alignment\n"
    fi
    
    if [[ "$LOAD_7HABITS" == "true" ]]; then
        context+="5. Analyze latest Covey 7 Habits analysis at $COVEY_FILE for development focus\n"
    fi
    
    if [[ "$LOAD_ADHD_TASKS" == "true" ]]; then
        context+="6. Review current ADHD tasks at $VAULT_DIR/ADHD-Tasks.md for priority areas\n"
    fi
    
    if [[ "$LOAD_PRIORITIES" == "true" ]]; then
        context+="7. Include Priority Management template at $VAULT_DIR/Priority-Management.md\n"
    fi
    
    if [[ "$LOAD_RECENT_QA" == "true" ]]; then
        context+="8. Review recent Q&A activity across topics for patterns and follow-up opportunities\n"
    fi
    
    if [[ "$LOAD_WEEKLY_REVIEW" == "true" ]]; then
        context+="9. Include latest weekly review for progress context\n"
    fi
    
    if [[ "$LOAD_DAILY_SUMMARY" == "true" ]]; then
        context+="10. Include recent daily summaries for current state awareness\n"
    fi
    
    if [[ "$RESEARCH_ONLINE" == "true" ]]; then
        context+="11. RESEARCH ENABLED: Use web search to gather current information when relevant\n"
        context+="12. Search for recent developments, best practices, or specific solutions\n"
        context+="13. Combine online research with biographical context for comprehensive responses\n"
    fi
    
    context+="\n"
    echo "$context"
}

# Apply smart defaults based on command if no context flags specified
apply_smart_defaults() {
    local command="$1"
    local context_flags_specified="$2"
    
    # Check if any context flags were specified (not workflow flags)
    local has_context_flags=false
    if [[ "$LOAD_BIOGRAPHY" == "true" || "$LOAD_MISSION" == "true" || "$LOAD_7HABITS" == "true" || 
          "$LOAD_ADHD_TASKS" == "true" || "$LOAD_PRIORITIES" == "true" || "$LOAD_RECENT_QA" == "true" || 
          "$LOAD_WEEKLY_REVIEW" == "true" || "$LOAD_DAILY_SUMMARY" == "true" || "$LOAD_ALL" == "true" ||
          "$FAST_MODE" == "true" ]]; then
        has_context_flags=true
    fi
    
    if [[ "$has_context_flags" == "false" ]]; then
        case "$command" in
            pop)
                # Biography + 7habits + adhd tasks for essential question finding
                LOAD_BIOGRAPHY=true
                LOAD_7HABITS=true
                LOAD_ADHD_TASKS=true
                ;;
            ask)
                # Biography for routing context
                LOAD_BIOGRAPHY=true
                ;;
            generate)
                # Biography + recent activity for question creation
                LOAD_BIOGRAPHY=true
                LOAD_RECENT_QA=true
                ;;
        esac
    fi
}

# Handle pop command - get most essential existing question
handle_pop() {
    local focus_area=""
    
    # Parse pop-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --focus)
                focus_area="$2"
                shift 2
                ;;
            *)
                echo "Unknown pop option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    log "Starting essentialist question prioritization session"
    [[ "$VERBOSE" == "true" ]] && echo "📖 Essentialist Biography Q&A - Finding the most essential question"
    
    local context=$(build_context_prompt)
    
    # Build essentialist prompt
    local ESSENTIALIST_PROMPT="${context}
TASK: Essentialist Question Prioritization

SYSTEM INFO:
- OS: $(uname -s) $(uname -r)
- Desktop: ${XDG_CURRENT_DESKTOP:-Unknown}
- Display: ${DISPLAY:-Not set}

OBJECTIVE:
1. Identify the single most important priority from current context
2. Scan relevant sources for existing unanswered questions (❌) related to that priority
3. Present the most essential question using the best available interface
4. Format question properly for shell execution (escape quotes, etc.)
5. Save response to appropriate topic via topic-manager integration

FOCUS AREA: ${focus_area:-Auto-detect from context}

DIALOG PRESENTATION:
- PREFERRED: Use notify-send with -A parameters for interactive responses
- FALLBACK: Use zenity or other dialog tools for complex interactions
- Handle response and save via topic-manager.sh routing

TOPIC INTEGRATION:
After getting response, use topic-manager to save:
- Call: $SCRIPTS_DIR/utils/topic-manager.sh route-question \"[question]\"
- Then: $SCRIPTS_DIR/utils/topic-manager.sh update-status \"[question]\" \"✅\" \"[answer]\""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN - Would execute pop with context:"
        echo "$context"
        return
    fi
    
    log "Executing essentialist prioritization with Claude"
    
    if [[ "$CONTINUE" == "true" ]]; then
        "$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue "$ESSENTIALIST_PROMPT"
    else
        "$SCRIPTS_DIR/utils/claude-wrapper.sh" "$ESSENTIALIST_PROMPT"
    fi
    
    log "Essentialist question prioritization completed"
}

# Handle ask command - present question(s)
handle_ask() {
    local question=""
    local from_file=""
    local batch_mode=false
    
    # Get question from arguments or stdin
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --from-file)
                from_file="$2"
                shift 2
                ;;
            --batch)
                batch_mode=true
                from_file="$2"
                shift 2
                ;;
            *)
                question="$*"
                ;;
        esac
    elif [[ ! -t 0 ]]; then
        # Read from pipe
        question=$(cat)
    fi
    
    if [[ -z "$question" && -z "$from_file" ]]; then
        echo "Usage: ask [question|--from-file file|--batch file]" >&2
        exit 1
    fi
    
    log "Starting ask session: ${question:-from file $from_file}"
    
    local context=$(build_context_prompt)
    
    if [[ -n "$from_file" ]]; then
        # Process questions from file
        if [[ ! -f "$from_file" ]]; then
            echo "File not found: $from_file" >&2
            exit 1
        fi
        
        local ASK_PROMPT="${context}
TASK: Process questions from file

INPUT FILE: $from_file

INSTRUCTIONS:
1. Read and analyze the input file: $from_file
2. Extract questions from the file (look for numbered format, markdown, or plain text)
3. For each question found:
   - Present it using the best available interface (notify-send, zenity, etc.)
   - Capture the user's response
   - Route through topic-manager to save in appropriate topic file
   - Use proper status symbols (✅ for answered questions)
   - Add timestamps for answers

BATCH MODE: ${batch_mode}
- If batch mode: Present all questions systematically with small delays
- If single mode: Process questions one by one with user confirmation

TOPIC INTEGRATION:
Use topic-manager for each question:
- Route: $SCRIPTS_DIR/utils/topic-manager.sh route-question \"[question]\"
- Save: $SCRIPTS_DIR/utils/topic-manager.sh update-status \"[question]\" \"✅\" \"[answer]\""
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "DRY RUN - Would process file: $from_file"
            echo "Context: $context"
            return
        fi
        
        log "Processing questions from file: $from_file"
    else
        # Single question
        local ASK_PROMPT="${context}
TASK: Present single question and save response

QUESTION: $question

INSTRUCTIONS:
1. Present the question using the best available interface
2. For simple questions, use notify-send with action buttons
3. For complex questions, use zenity or other dialog tools
4. Capture the user's response
5. Route through topic-manager to save in appropriate topic file

TOPIC INTEGRATION:
After getting response:
- Route: $SCRIPTS_DIR/utils/topic-manager.sh route-question \"$question\"  
- Save: $SCRIPTS_DIR/utils/topic-manager.sh update-status \"$question\" \"✅\" \"[answer]\""
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "DRY RUN - Would ask: $question"
            echo "Context: $context"
            return
        fi
        
        log "Presenting single question: $question"
    fi
    
    if [[ "$CONTINUE" == "true" ]]; then
        "$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue "$ASK_PROMPT"
    else
        "$SCRIPTS_DIR/utils/claude-wrapper.sh" "$ASK_PROMPT"
    fi
    
    log "Ask session completed"
}

# Handle generate command - create new questions
handle_generate() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: generate <target> [count] [options]" >&2
        echo "  generate --challenges N       Generate N challenge-based questions"
        echo "  generate --gaps N             Generate N gap-filling questions"
        echo "  generate \"Topic Name\" N       Generate N questions for specific topic"
        exit 1
    fi
    
    local target="$1"
    local count="${2:-5}"
    local interactive=false
    
    # Parse generate-specific options
    shift 2
    while [[ $# -gt 0 ]]; do
        case $1 in
            --interactive)
                interactive=true
                shift
                ;;
            *)
                echo "Unknown generate option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    log "Starting question generation: $target (count: $count)"
    
    local context=$(build_context_prompt)
    
    local GENERATE_PROMPT="${context}
TASK: Generate new questions

TARGET: $target
COUNT: $count
INTERACTIVE: $interactive

INSTRUCTIONS:
1. Based on the loaded context, generate $count high-quality questions
2. Target type: $target
   - If \"--challenges\": Focus on current biggest challenges and obstacles
   - If \"--gaps\": Focus on filling knowledge gaps in the biography
   - If topic name: Focus on that specific topic area
3. Questions should be:
   - Actionable and specific
   - Relevant to current priorities and context
   - Answerable with concrete responses
   - Likely to generate valuable insights

PROCESSING:
- If interactive: Present each question for immediate answering
- If not interactive: Just generate and save questions to appropriate topics
- Use topic-manager to route and save questions appropriately
- Format as proper biography questions with ❌ status

TOPIC INTEGRATION:
For each generated question:
- Route: $SCRIPTS_DIR/utils/topic-manager.sh route-question \"[question]\"
- Add: $SCRIPTS_DIR/utils/topic-manager.sh add-question \"[topic]\" \"[question]\""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN - Would generate: $target (count: $count, interactive: $interactive)"
        echo "Context: $context"
        return
    fi
    
    log "Executing question generation with Claude"
    
    if [[ "$CONTINUE" == "true" ]]; then
        "$SCRIPTS_DIR/utils/claude-wrapper.sh" --continue "$GENERATE_PROMPT"
    else
        "$SCRIPTS_DIR/utils/claude-wrapper.sh" "$GENERATE_PROMPT"
    fi
    
    log "Question generation completed"
}

# Handle help command
handle_help() {
    local help_command="$1"
    
    case "$help_command" in
        ask)
            cat << 'EOF'
ask - Present and save question(s)

USAGE:
  question-manager.sh [-flags] ask [question]
  question-manager.sh [-flags] ask --from-file <file>
  question-manager.sh [-flags] ask --batch <file>
  echo "question" | question-manager.sh [-flags] ask

DESCRIPTION:
  Present questions and save responses to the biography system.
  Supports single questions, batch processing, and file input.

OPTIONS:
  question              Single question text
  --from-file <file>    Process questions from Claude output file
  --batch <file>        Process multiple questions from file

EXAMPLES:
  question-manager.sh -b ask "What's blocking me?"
  question-manager.sh -rb7 ask "Latest productivity trends?"
  question-manager.sh -c ask "Follow-up question?"
  echo "Morning routine issue?" | question-manager.sh -b ask
  question-manager.sh ask --from-file analysis-output.txt

CONTEXT FLAGS:
  Use context flags to load relevant information:
  -b (biography), -7 (7habits), -r (research), etc.
  
EOF
            ;;
        pop)
            cat << 'EOF'
pop - Get most essential existing question

USAGE:
  question-manager.sh [-flags] pop [--focus <area>]

DESCRIPTION:
  Uses essentialist principles to identify and present the single
  most important unanswered question from your biography system.

OPTIONS:
  --focus <area>        Focus on specific area (e.g., "morning-routine")

EXAMPLES:
  question-manager.sh pop                    # Default context: -b7a
  question-manager.sh -b7am pop             # Comprehensive context
  question-manager.sh -f pop                # Fast, minimal context
  question-manager.sh pop --focus career    # Career-focused

DEFAULT CONTEXT:
  Without flags, pop uses -b7a (biography + 7habits + adhd-tasks)
  for optimal essential question identification.

EOF
            ;;
        generate)
            cat << 'EOF'
generate - Create new questions

USAGE:
  question-manager.sh [-flags] generate --challenges <N> [--interactive]
  question-manager.sh [-flags] generate --gaps <N> [--interactive]  
  question-manager.sh [-flags] generate "<topic>" <N> [--interactive]

DESCRIPTION:
  Generate new questions based on biography analysis and current context.
  Questions are automatically routed to appropriate topics.

TARGETS:
  --challenges <N>      Generate N questions about current challenges
  --gaps <N>           Generate N questions to fill knowledge gaps
  "<topic>" <N>        Generate N questions for specific topic

OPTIONS:
  --interactive        Present questions immediately for answering

EXAMPLES:
  question-manager.sh -rb7 generate --challenges 5
  question-manager.sh generate --gaps 3 --interactive  
  question-manager.sh -b generate "Health" 5
  question-manager.sh -rA generate --challenges 3 --interactive

DEFAULT CONTEXT:
  Without flags, generate uses -bq (biography + recent-qa)

EOF
            ;;
        flags)
            cat << 'EOF'
CONTEXT FLAGS (stackable like ls -la):

Core Context:
  -b  biography       Biography.md + explore linked topics as needed
  -m  mission         Mission statement for priority alignment
  -7  7habits         Covey 7 Habits analysis for development focus
  -a  adhd-tasks      ADHD tasks for current priorities
  -p  priorities      Priority Management template
  -q  recent-qa       Recent Q&A activity across topics
  -w  weekly-review   Latest weekly review
  -d  daily-summary   Recent daily summaries

Research & Workflow:
  -r  research        Enable online web search capability
  -c  continue        Continue previous Claude conversation (fast)
  -f  fast            Minimal context for speed
  -A  all             All context sources (excludes research)
  -v  verbose         Verbose output
  -n  dry-run         Show what would be loaded without executing

EXAMPLES:
  -b7a     Biography + 7 Habits + ADHD tasks
  -rb7m    Research + Biography + 7 Habits + Mission  
  -c       Continue previous conversation (fast)
  -A       All available context sources

EOF
            ;;
        *)
            show_usage
            ;;
    esac
}

# Main function
main() {
    local flags=""
    local command=""
    local flags_specified=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -*)
                flags="$1"
                flags_specified=true
                parse_flags "$flags"
                shift
                ;;
            ask|pop|generate|help)
                command="$1"
                shift
                break
                ;;
            *)
                echo "Unknown argument: $1" >&2
                show_usage
                ;;
        esac
    done
    
    # Validate command
    if [[ -z "$command" ]]; then
        show_usage
    fi
    
    # Apply smart defaults if no flags specified
    apply_smart_defaults "$command" "$flags_specified"
    
    log "Starting question-manager: $command with flags: $flags (biography:$LOAD_BIOGRAPHY, 7habits:$LOAD_7HABITS, adhd:$LOAD_ADHD_TASKS)"
    [[ "$VERBOSE" == "true" ]] && echo "Question Manager: $command"
    
    # Dispatch to appropriate handler
    case "$command" in
        ask)
            handle_ask "$@"
            ;;
        pop)
            handle_pop "$@"
            ;;
        generate)
            handle_generate "$@"
            ;;
        help)
            handle_help "$@"
            ;;
        *)
            echo "Unknown command: $command" >&2
            show_usage
            ;;
    esac
    
    log "Question-manager completed: $command"
}

# Execute main function with all arguments
main "$@"