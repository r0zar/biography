#!/bin/bash

# Bootstrap Questions Generator
# Creates initial questions for new users across key life areas
# Provides foundation context for the biography system

# Auto-load configuration
source "$(dirname "$0")/../utils/auto-config.sh"

# Set environment for proper operations
export DISPLAY="${DISPLAY:-:1}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$BIOGRAPHY_LOG"
}

echo "🚀 Biography System Bootstrap - Initial Question Generation"
echo "Creating foundation questions across key life areas..."

log "Starting bootstrap question generation for new user"

# Comprehensive bootstrap prompt for new users
BOOTSTRAP_PROMPT="BIOGRAPHY SYSTEM BOOTSTRAP - Generate Initial Foundation Questions

CONTEXT: This is a NEW USER with an empty biography system. I need to generate 12-15 diverse foundation questions that will:
1. Build essential context data for the biography system
2. Cover key life areas comprehensively
3. Enable effective future question prioritization
4. Create initial topic structure in Obsidian vault

REQUIRED COVERAGE AREAS (2-3 questions each):

**1. Career & Professional Life**
- Current career situation, satisfaction, goals
- Skills, achievements, transition needs
- Work-life balance and professional priorities

**2. Personal Effectiveness & Habits**  
- Daily routines, productivity patterns
- Time management, priority-setting habits
- Personal discipline and consistency areas

**3. Relationships & Family**
- Family relationships, communication patterns
- Social connections, relationship satisfaction
- Support systems and relationship priorities

**4. Personal Identity & Values**
- Core values, life philosophy
- Personal mission, purpose clarity
- Identity, self-understanding, growth areas

**5. Health & Life Management**
- Physical health, wellness routines
- Financial situation, money management
- Life balance, stress management

QUESTION GENERATION PROCESS:
For each area, create 2-3 diverse questions that:
- Use simple yes/no or specific choice formats for easy answering
- Target foundational information that enables future context-aware questions
- Avoid being too personal or overwhelming for a first session
- Create broad understanding rather than deep specifics
- Enable topic-manager routing to appropriate topic areas

FOR EACH QUESTION:
1. Generate the question text
2. Use topic-manager.sh route-question to determine optimal topic
3. Add question to topic using topic-manager.sh add-question
4. Present question using available dialog interface (notify-send preferred)
5. Wait for user response before proceeding to next question

PACING: Present questions one at a time with brief pauses between. This is an initial session to build foundation context, not an interrogation.

GOAL: After this session, the system should have:
- 5-10 answered foundation questions across life areas
- Multiple topic files with initial Q&As
- Enough context for intelligent future question generation
- User familiarity with the notification-based Q&A process

Begin with the first question from Career & Professional Life area."

log "Executing bootstrap question generation"
"$SCRIPTS_DIR/utils/claude-wrapper.sh" "$BOOTSTRAP_PROMPT"

log "Bootstrap question generation completed"

echo ""
echo "✅ Initial questions generated and presented!"
echo ""
echo "Next steps:"
echo "1. Answer the questions that were presented via notifications"
echo "2. Check your Obsidian vault - topic files have been created with your questions"
echo "3. Once you've answered 5-10 questions, run: ./setup/mission-statement-builder.sh"
echo "4. After creating your mission statement, the system is ready for automation"
echo ""
echo "The system will learn from your answers and ask increasingly relevant questions."