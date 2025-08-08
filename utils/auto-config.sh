#!/bin/bash

# Auto-Configuration for Biography System
# This sets up environment variables automatically when any script runs
# All scripts will automatically source this

# Only load once per session
if [[ -n "$BIOGRAPHY_CONFIG_LOADED" ]]; then
    return 0 2>/dev/null || exit 0
fi

# Detect script directory (utils is in biography root, so go up one level)
SCRIPTS_DIR="${SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Core directories - can be overridden with environment variables
export VAULT_DIR="${VAULT_DIR:-$HOME/Documents/Obsidian Vault}"
export LOGS_DIR="${LOGS_DIR:-$SCRIPTS_DIR/logs}"
export TOPICS_DIR="${TOPICS_DIR:-$VAULT_DIR/Topics}"
export PROMPTS_DIR="${PROMPTS_DIR:-$SCRIPTS_DIR/prompts}"

# Key files
export BIOGRAPHY_FILE="${BIOGRAPHY_FILE:-$VAULT_DIR/Biography.md}"
export MISSION_FILE="${MISSION_FILE:-$VAULT_DIR/Mission Statement.md}"
export COVEY_FILE="${COVEY_FILE:-$VAULT_DIR/Covey-Life-Analysis.md}"
export ADHD_TASKS_FILE="${ADHD_TASKS_FILE:-$VAULT_DIR/ADHD-Tasks.md}"

# Prompt files
export COVEY_PROMPT_FILE="${COVEY_PROMPT_FILE:-$PROMPTS_DIR/stephen-covey-instructions.md}"
export ESSENTIALIST_PROMPT_FILE="${ESSENTIALIST_PROMPT_FILE:-$PROMPTS_DIR/greg-mckeown-essentialist-instructions.md}"

# Template files
export QUESTION_FORMAT_TEMPLATE="${QUESTION_FORMAT_TEMPLATE:-$SCRIPTS_DIR/templates/question-generation-format.md}"

# Log files
export BIOGRAPHY_LOG="${BIOGRAPHY_LOG:-$LOGS_DIR/biography-questions.log}"
export COVEY_LOG="${COVEY_LOG:-$LOGS_DIR/covey-analysis.log}"
export TOPIC_MANAGER_LOG="${TOPIC_MANAGER_LOG:-$LOGS_DIR/topic-manager.log}"

# Claude settings
export CLAUDE_MODEL="${CLAUDE_MODEL:-sonnet}"

# Export scripts dir
export SCRIPTS_DIR

# Ensure required directories exist
mkdir -p "$LOGS_DIR"
mkdir -p "$PROMPTS_DIR"

# Mark as loaded
export BIOGRAPHY_CONFIG_LOADED=1