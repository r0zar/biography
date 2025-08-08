#!/usr/bin/env python3
"""
Automatic Configuration for Biography System Python Scripts
This module automatically loads environment variables with sensible defaults.
Import this at the top of any Python script to get automatic configuration.
"""

import os
from pathlib import Path

# Get script directory (utils is in scripts, so go up one level)
SCRIPTS_DIR = str(Path(__file__).parent.parent.absolute())

# Auto-load environment variables with defaults
os.environ.setdefault('SCRIPTS_DIR', SCRIPTS_DIR)
os.environ.setdefault('VAULT_DIR', str(
    Path.home() / 'Documents' / 'Obsidian Vault'))
os.environ.setdefault('LOGS_DIR', str(Path.home() / 'logs'))
os.environ.setdefault('TOPICS_DIR', os.path.join(
    os.environ['VAULT_DIR'], 'Topics'))
os.environ.setdefault('PROMPTS_DIR', os.path.join(SCRIPTS_DIR, 'prompts'))
os.environ.setdefault('BIOGRAPHY_FILE', os.path.join(
    os.environ['VAULT_DIR'], 'Biography.md'))
os.environ.setdefault('MISSION_FILE', os.path.join(
    os.environ['VAULT_DIR'], 'Mission Statement.md'))
os.environ.setdefault('COVEY_FILE', os.path.join(
    os.environ['VAULT_DIR'], 'Covey-Life-Analysis.md'))
os.environ.setdefault('ADHD_TASKS_FILE', os.path.join(
    os.environ['VAULT_DIR'], 'ADHD-Tasks.md'))
os.environ.setdefault('BIOGRAPHY_PROMPT_FILE', os.path.join(
    os.environ['PROMPTS_DIR'], 'biography_instructions.md'))
os.environ.setdefault('COVEY_PROMPT_FILE', os.path.join(
    os.environ['PROMPTS_DIR'], 'stephen-covey-instructions.md'))
os.environ.setdefault('BIOGRAPHY_LOG', os.path.join(
    os.environ['LOGS_DIR'], 'biography-questions.log'))
os.environ.setdefault('COVEY_LOG', os.path.join(
    os.environ['LOGS_DIR'], 'covey-analysis.log'))
os.environ.setdefault('TOPIC_MANAGER_LOG', os.path.join(
    os.environ['LOGS_DIR'], 'topic-manager.log'))
os.environ.setdefault('CLAUDE_MODEL', 'sonnet')

# Create required directories
Path(os.environ['LOGS_DIR']).mkdir(parents=True, exist_ok=True)
Path(os.environ['PROMPTS_DIR']).mkdir(parents=True, exist_ok=True)

# Export convenient constants
VAULT_DIR = os.environ['VAULT_DIR']
LOGS_DIR = os.environ['LOGS_DIR']
TOPICS_DIR = os.environ['TOPICS_DIR']
PROMPTS_DIR = os.environ['PROMPTS_DIR']
BIOGRAPHY_FILE = os.environ['BIOGRAPHY_FILE']
MISSION_FILE = os.environ['MISSION_FILE']
COVEY_FILE = os.environ['COVEY_FILE']
ADHD_TASKS_FILE = os.environ['ADHD_TASKS_FILE']
BIOGRAPHY_PROMPT_FILE = os.environ['BIOGRAPHY_PROMPT_FILE']
COVEY_PROMPT_FILE = os.environ['COVEY_PROMPT_FILE']
BIOGRAPHY_LOG = os.environ['BIOGRAPHY_LOG']
COVEY_LOG = os.environ['COVEY_LOG']
TOPIC_MANAGER_LOG = os.environ['TOPIC_MANAGER_LOG']
CLAUDE_MODEL = os.environ['CLAUDE_MODEL']

# Debug function


def show_config():
    """Show current configuration"""
    print("=== Biography System Configuration ===")
    for key in sorted(os.environ.keys()):
        if key.startswith(('VAULT_', 'LOGS_', 'TOPICS_', 'PROMPTS_', 'BIOGRAPHY_', 'MISSION_', 'COVEY_', 'ADHD_', 'CLAUDE_', 'SCRIPTS_')):
            print(f"{key}: {os.environ[key]}")


if __name__ == "__main__":
    show_config()
