#!/bin/bash

# Biography Questions Script
# Uses Greg McKeown's Essentialism principles to identify the most essential existing question

# Auto-load configuration
source "$(dirname "$0")/../utils/auto-config.sh"

# Set GUI environment variables for proper dialog display
export DISPLAY="${DISPLAY:-:1}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# Get theme settings from user's actual environment
# if command -v gsettings >/dev/null 2>&1; then
#     USER_GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
#     if [ -n "$USER_GTK_THEME" ] && [ "$USER_GTK_THEME" != "null" ]; then
#         export GTK_THEME="$USER_GTK_THEME"
#     fi
# fi

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$BIOGRAPHY_LOG"
}

log "Starting essentialist question prioritization session"

echo "📖 Essentialist Biography Q&A - Asking the most essential question"

# Execute essentialist question prioritization
ESSENTIALIST_PROMPT="Please perform essentialist question prioritization:

SYSTEM INFO:
- OS: $(uname -s) $(uname -r)
- Desktop: ${XDG_CURRENT_DESKTOP:-Unknown}
- Display: ${DISPLAY:-Not set}

CONTEXT LOADING:
1. Read the agent instructions at $ESSENTIALIST_PROMPT_FILE
2. Read Priority Management file at $VAULT_DIR/Priority-Management.md
3. Read Covey analysis at $COVEY_FILE
4. Read mission statement at $MISSION_FILE
5. Read current ADHD tasks file at $VAULT_DIR/ADHD-Tasks.md to identify the top priority areas

TASK:
1. Identify the single most important priority from the ADHD tasks file (morning discipline, job performance, etc.)
2. Scan the relevant topic files for existing unanswered questions (❌) related to that priority
3. If suitable question exists, select it for presentation
4. If no suitable question exists, create a new essential question that:
   - Addresses the specific ADHD task priority identified
   - Can be answered with actionable yes/no or specific options
   - Helps overcome the current completion rate bottlenecks (17% job apps, 29% morning discipline)
   - Add this new question to the most appropriate topic file with ❌ status
5. Present the selected/created question using the most appropriate dialog interface

DIALOG PRESENTATION:
- PREFERRED: If question is short (under 80 characters) and has simple yes/no or 2-3 option responses, use notify-send with action buttons for lightweight interaction
- FALLBACK: For longer/complex questions, use dialog tools like zenity
- Format question text properly for shell execution (escape quotes, etc.)
- Create appropriate button options based on question type
- For notifications: Use notify-send with -A parameters for interactive responses
  * Returns numeric index: 0=first button, 1=second button, etc.  
  * More reliable than dialog windows for text visibility
  * Integrates naturally with desktop environment
- For dialogs: Current GTK_THEME is set to: ${GTK_THEME:-default}
- Handle response and update markdown file with proper status and timestamp"

log "Applying essentialist principles to identify the most critical existing question"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$ESSENTIALIST_PROMPT"

log "Essentialist question prioritization completed"