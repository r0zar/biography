#!/bin/bash

# Topic Manager - Utility for managing focused Q&A topic pages
# Handles creation, linking, and management of topic-specific Q&A files

# Auto-load configuration
source "$(dirname "$0")/auto-config.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$TOPIC_MANAGER_LOG"
}

# Function to create a new topic Q&A page
create_topic_page() {
    local topic_name="$1"
    local topic_file="$TOPICS_DIR/${topic_name}.md"
    
    # Ensure Topics directory exists
    mkdir -p "$TOPICS_DIR"
    
    if [ -f "$topic_file" ]; then
        log "Topic page already exists: $topic_file"
        return 0
    fi
    
    log "Creating new topic page: $topic_file"
    
    # Create the topic page with standard structure
    cat > "$topic_file" << EOF
# ${topic_name}

*This page contains focused Q&A sessions related to ${topic_name,,}. Questions are generated contextually based on biography data and dimensional analyses.*

## Question Status Legend
- ❌ Not asked yet  
- ⏳ Asked, awaiting response
- ✅ Answered
- ⏭ Skipped

---

## Active Topics to Explore

*Use this section to track current themes and areas that should be explored*

### Key Areas
- Current developments and changes
- Challenges and how they're being handled
- Goals and aspirations in this area
- Recent learnings or insights

---

## Questions & Responses

*Questions will be automatically added here by the biography system*

---

**Links:** [[Biography]] | [[Career Transition]] | [[Personal Effectiveness]]

*Generated on $(date '+%B %d, %Y at %I:%M %p')*
EOF
    
    log "Created topic page: $topic_file"
    
    # Add link to Biography.md if not already present
    add_topic_link_to_biography "$topic_name"
}

# Function to add topic link to Biography.md
add_topic_link_to_biography() {
    local topic_name="$1"
    
    # Don't add Biography as a link to itself
    if [ "$topic_name" = "Biography" ]; then
        log "Skipping self-reference link for Biography"
        return 0
    fi
    
    local link_pattern="\[\[Topics/${topic_name}\]\]"
    
    if grep -q "$link_pattern" "$BIOGRAPHY_FILE"; then
        log "Link to $topic_name already exists in Biography.md"
        return 0
    fi
    
    log "Adding link to $topic_name in Biography.md"
    
    # Add link to the "Related Topics" section, creating it if needed
    if ! grep -q "## Related Topics" "$BIOGRAPHY_FILE"; then
        echo -e "\n---\n\n## Related Topics\n\n*Focused Q&A pages for specific areas:*\n" >> "$BIOGRAPHY_FILE"
    fi
    
    # Add the link
    sed -i "/## Related Topics/a\\- [[Topics/${topic_name}]] - Focused Q&A for ${topic_name,,}" "$BIOGRAPHY_FILE"
    
    log "Added link to $topic_name in Biography.md"
}

# Function to add question to specific topic file
add_question_to_topic() {
    local topic_name="$1"
    local question="$2"
    
    # Never route to Biography.md - always use topic pages
    if [ "$topic_name" = "Biography" ]; then
        # Redirect to appropriate topic page instead
        topic_name=$(determine_topic_from_question "$question")
        log "Redirecting Biography question to $topic_name: $question"
    fi
    
    # Legacy handling kept for reference but never executed
    if false && [ "$topic_name" = "Biography" ]; then
        # Use Python to insert questions in the appropriate section based on content
        python3 << EOF
import re

question = "$question"

# Read the Biography file
with open("$BIOGRAPHY_FILE", 'r', encoding='utf-8') as f:
    content = f.read()

# Determine appropriate section based on question content
def get_target_section(question):
    question_lower = question.lower()
    
    # Map question patterns to Biography.md sections
    if any(word in question_lower for word in ['mission statement', 'core values', 'life purpose', 'principles', 'philosophy']):
        return "### Core Values"
    elif any(word in question_lower for word in ['career transition', 'career pivot', 'career change', 'pivot story', 'technical achievements']):
        return "### Current Career Transition"
    elif any(word in question_lower for word in ['childhood', 'growing up', 'parents', 'family', 'siblings']):
        return "### Childhood"
    elif any(word in question_lower for word in ['school', 'college', 'university', 'education', 'study']):
        return "### Higher Education"
    elif any(word in question_lower for word in ['relationship', 'married', 'partner', 'friends', 'family']):
        return "### Relationships"
    elif any(word in question_lower for word in ['hobbies', 'interests', 'passionate', 'free time', 'technology', 'programming']):
        return "### Current Interests"
    elif any(word in question_lower for word in ['goals', 'dreams', 'aspirations', 'future']):
        return "### Goals & Dreams"
    elif any(word in question_lower for word in ['travel', 'adventurous', 'experiences', 'skills']):
        return "### Experiences"
    elif any(word in question_lower for word in ['favorite', 'prefer', 'morning person', 'night owl', 'season', 'food']):
        return "### Preferences"
    elif any(word in question_lower for word in ['physical', 'exercise', 'movement', 'stretching', 'break', 'workday', 'health', 'wellness']):
        return "### Personal Basics"
    else:
        return None  # Will be inserted before Related Topics

# Find target section
target_section = get_target_section(question)
question_line = "- ❌ " + question

if target_section:
    # Find the target section
    section_pattern = re.escape(target_section)
    section_match = re.search(section_pattern, content)
    
    if section_match:
        # Find the end of this section (next ### or ## heading or Related Topics)
        section_start = section_match.end()
        next_section_match = re.search(r'\\n(###|##)', content[section_start:])
        
        if next_section_match:
            # Insert before the next section
            insertion_point = section_start + next_section_match.start()
            new_content = content[:insertion_point] + "\\n" + question_line + content[insertion_point:]
        else:
            # Insert at the end of the section
            new_content = content[:section_start] + "\\n" + question_line + "\\n" + content[section_start:]
    else:
        # Section not found, fall back to before Related Topics
        insertion_point = content.find("## Related Topics")
        if insertion_point != -1:
            new_content = content[:insertion_point] + question_line + "\\n\\n" + content[insertion_point:]
        else:
            new_content = content + "\\n" + question_line + "\\n"
else:
    # No specific section, insert before Related Topics
    insertion_point = content.find("## Related Topics")
    if insertion_point != -1:
        new_content = content[:insertion_point] + question_line + "\\n\\n" + content[insertion_point:]
    else:
        new_content = content + "\\n" + question_line + "\\n"

# Write back to file
with open("$BIOGRAPHY_FILE", 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Added question to Biography section: {target_section or 'General'}")
EOF
        log "Added question to Biography: $question"
        return 0
    fi
    
    # For other topics, use the Topics directory
    local topic_file="$TOPICS_DIR/${topic_name}.md"
    
    # Create topic page if it doesn't exist
    if [ ! -f "$topic_file" ]; then
        create_topic_page "$topic_name"
    fi
    
    # Insert question in the proper "Questions & Responses" section using Python
    python3 << EOF
import re
import os

topic_file = "$topic_file"
question = "$question"

# Read the topic file
with open(topic_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Look for the "Questions & Responses" section
questions_section = "## Questions & Responses"
questions_marker = "*Questions will be automatically added here by the biography system*"

if questions_section in content and questions_marker in content:
    # Insert after the marker but before any existing questions
    marker_pos = content.find(questions_marker)
    if marker_pos != -1:
        # Find the end of the marker line
        end_of_line = content.find("\\n", marker_pos)
        if end_of_line != -1:
            # Insert the question after the marker with proper spacing
            question_line = "\\n\\n- ❌ " + question
            new_content = content[:end_of_line] + question_line + content[end_of_line:]
        else:
            # Fallback: append to end
            new_content = content + "\\n- ❌ " + question + "\\n"
    else:
        # Fallback: append to end
        new_content = content + "\\n- ❌ " + question + "\\n"
else:
    # Fallback: append to end if section not found
    new_content = content + "\\n- ❌ " + question + "\\n"

# Write back to file
with open(topic_file, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Added question to proper section")
EOF
    
    log "Added question to $topic_name: $question"
}

# Function to determine which topic file a question belongs to using Claude
determine_question_topic() {
    local question="$1"
    
    # First, check for obvious patterns that should go to specific existing topics
    case "$question" in
        *interview*|*behavioral*|*"Tell me about yourself"*|*whiteboard*|*"career pivot story"*|*"technical achievements"*|*"elevator pitch"*|*"mock interview"*|*"interview preparation"*)
            echo "Interview Performance"
            return
            ;;
        *"job search"*|*"networking"*|*"applying"*|*"applications"*|*"companies"*|*"positions"*|*"backup options"*|*"informational interviews"*)
            echo "Job Search Strategy" 
            return
            ;;
        *"career transition"*|*"career pivot"*|*"career change"*|*"transition"*|*"field"*|*"industry"*|*"professional identity"*)
            echo "Career Transition"
            return
            ;;
        *"technical"*|*"programming"*|*"coding"*|*"technologies"*|*"skills"*|*"portfolio"*|*"projects"*)
            echo "Technical Skills"
            return
            ;;
        *"priorities"*|*"planning"*|*"routine"*|*"effectiveness"*|*"productivity"*|*"focus"*|*"overwhelm"*|*"time management"*)
            echo "Personal Effectiveness"
            return
            ;;
        *"weekly"*|*"daily"*|*"schedule"*|*"weekly review"*|*"weekly planning"*)
            echo "Weekly Planning"
            return
            ;;
        *"learning"*|*"goals"*|*"aspirations"*|*"development"*|*"growth"*)
            echo "Learning Goals"
            return
            ;;
        *"financial"*|*"finances"*|*"money"*|*"budget"*|*"expenses"*|*"income"*|*"savings"*|*"debt"*|*"salary"*|*"runway"*|*"security"*)
            echo "Personal Finances"
            return
            ;;
    esac
    
    # Use Claude for more complex routing decisions
    local claude_prompt="Given this biography question: \"$question\"

Available existing topic pages:
- Interview Performance: Interview prep, behavioral questions, technical interviews, presentation skills
- Job Search Strategy: Application tracking, networking, company research, job hunting tactics
- Career Transition: Career pivots, professional identity, field changes, transition challenges  
- Technical Skills: Programming, coding projects, technical abilities, portfolio work
- Personal Effectiveness: Time management, productivity, focus, priorities, overwhelm
- Weekly Planning: Daily/weekly routines, scheduling, planning processes
- Learning Goals: Skill development, growth objectives, educational pursuits
- Personal Finances: Money management, budgeting, financial security, expenses, income, savings

Analyze the question and determine the most appropriate topic category:

Rules:
- NEVER return Biography - always use a focused topic page
- If about basic personal info/demographics: Personal Identity
- If about childhood/family background: Early Life  
- If about education: Education Journey
- If about general relationships: Relationships
- If about values/beliefs/philosophy: Life Philosophy
- If about hobbies/interests: Interests & Hobbies
- If it clearly fits an existing topic above, return that exact topic name
- Only suggest a new topic if the question covers a significant area not addressed by existing topics
- Topic names should be 2-3 words, title case
- Consider the person is currently job searching and transitioning careers

Return ONLY the topic name, nothing else."

    # Get topic recommendation from Claude
    local topic=$("$SCRIPTS_DIR/utils/claude-wrapper.sh" "$claude_prompt" 2>/dev/null | tail -1 | tr -d '\n')
    
    # Default to Personal Identity if Claude call fails or returns empty
    if [ -z "$topic" ] || [ "$topic" = "" ]; then
        echo "Personal Identity"
    else
        echo "$topic"
    fi
}

# Function to determine topic from question content (fallback for Biography routing)
determine_topic_from_question() {
    local question="$1"
    local question_lower=$(echo "$question" | tr '[:upper:]' '[:lower:]')
    
    # Map question patterns to existing topic pages
    if [[ $question_lower == *"parent"* || $question_lower == *"family"* || $question_lower == *"childhood"* || $question_lower == *"sibling"* ]]; then
        echo "Early Life"
    elif [[ $question_lower == *"school"* || $question_lower == *"college"* || $question_lower == *"university"* || $question_lower == *"education"* ]]; then
        echo "Education Journey"
    elif [[ $question_lower == *"job"* || $question_lower == *"career"* || $question_lower == *"work"* || $question_lower == *"interview"* ]]; then
        echo "Career Transition"
    elif [[ $question_lower == *"friend"* ]]; then
        echo "Friendships"
    elif [[ $question_lower == *"relationship"* || $question_lower == *"partner"* || $question_lower == *"married"* ]]; then
        echo "Relationships"
    elif [[ $question_lower == *"hobby"* || $question_lower == *"interest"* || $question_lower == *"technology"* || $question_lower == *"programming"* ]]; then
        echo "Interests & Hobbies"
    elif [[ $question_lower == *"value"* || $question_lower == *"belief"* || $question_lower == *"philosophy"* || $question_lower == *"purpose"* ]]; then
        echo "Life Philosophy"
    elif [[ $question_lower == *"mission"* || $question_lower == *"statement"* ]]; then
        echo "Mission Statement"
    elif [[ $question_lower == *"goal"* || $question_lower == *"plan"* || $question_lower == *"future"* ]]; then
        echo "Weekly Planning"
    elif [[ $question_lower == *"money"* || $question_lower == *"financial"* || $question_lower == *"budget"* || $question_lower == *"income"* ]]; then
        echo "Personal Finances"
    elif [[ $question_lower == *"scale ai"* || $question_lower == *"interview"* ]]; then
        echo "Scale AI Interview"
    else
        # Default to Personal Identity for basic personal info
        echo "Personal Identity"
    fi
}

# Function to get topic file path
get_topic_file_path() {
    local topic_name="$1"
    if [ "$topic_name" = "Biography" ]; then
        echo "$BIOGRAPHY_FILE"
    else
        echo "$TOPICS_DIR/${topic_name}.md"
    fi
}

# Function to update question status in appropriate topic file
update_question_status_in_topic() {
    local question="$1"
    local status="$2"
    local answer="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Search for the question across all topic files and Biography.md
    # Handle both clean questions and questions with custom label format
    local found_file=""
    local actual_question_line=""
    
    for file in "$BIOGRAPHY_FILE" "$TOPICS_DIR"/*.md; do
        if [ -f "$file" ]; then
            # Look for questions that start with this text but may have {label} format
            local found_line=$(grep "❌ $question" "$file" 2>/dev/null | head -1)
            if [ -n "$found_line" ]; then
                found_file="$file"
                actual_question_line="${found_line#*❌ }"  # Remove "❌ " prefix
                break
            fi
        fi
    done
    
    if [ -z "$found_file" ]; then
        log "Question not found in any topic file: $question"
        return 1
    fi
    
    # Update the question status using the actual question line found
    local old_pattern="- ❌ $actual_question_line"
    local new_line=""
    
    # For the updated line, use the clean question (without custom labels)
    case "$status" in
        "yes") new_line="- ✅ $question\n  **Answer:** $answer *(answered $timestamp)*" ;;
        "no") new_line="- ✅ $question\n  **Answer:** No *(answered $timestamp)*" ;;
        "skip") new_line="- ⏭ $question *(skipped $timestamp)*" ;;
        *) new_line="- ⏳ $question *(asked $timestamp)*" ;;
    esac
    
    # Use sed to replace the first occurrence  
    sed -i "0,/$(echo "$old_pattern" | sed 's/[[\.*^$()+?{|]/\\&/g')/{s/$(echo "$old_pattern" | sed 's/[[\.*^$()+?{|]/\\&/g')/$(echo "$new_line" | sed 's/[[\.*^$()+?{|]/\\&/g')/}" "$found_file"
    
    log "Updated question status in $(basename "$found_file"): $actual_question_line -> $status"
}

# Main function to handle command line arguments
main() {
    case "$1" in
        "create")
            if [ -z "$2" ]; then
                echo "Usage: $0 create <topic_name>"
                exit 1
            fi
            create_topic_page "$2"
            ;;
        "add-question")
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo "Usage: $0 add-question <topic_name> <question>"
                exit 1
            fi
            add_question_to_topic "$2" "$3"
            ;;
        "route-question")
            if [ -z "$2" ]; then
                echo "Usage: $0 route-question <question>"
                exit 1
            fi
            determine_question_topic "$2"
            ;;
        "update-status")
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo "Usage: $0 update-status <question> <status> [answer]"
                exit 1
            fi
            update_question_status_in_topic "$2" "$3" "$4"
            ;;
        *)
            echo "Usage: $0 {create|add-question|route-question|update-status}"
            echo "  create <topic_name>                 - Create new topic Q&A page"
            echo "  add-question <topic_name> <question> - Add question to topic"
            echo "  route-question <question>           - Determine topic for question"
            echo "  update-status <question> <status> [answer] - Update question status"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"