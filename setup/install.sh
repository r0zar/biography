#!/bin/bash

# Biography System Installation Script
# One-command setup for the Biography Q&A Automation System

set -e  # Exit on any error

echo "🚀 Biography Q&A System Installation"
echo "======================================"

# Get the directory where this script is located (should be biography/setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📁 Installing to: $PROJECT_DIR"

# Load configuration
source "$PROJECT_DIR/utils/auto-config.sh"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt user
prompt_user() {
    read -p "$1 (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

echo ""
echo "🔧 Checking Prerequisites..."

# Check Python
if ! command_exists python3; then
    echo "❌ Python 3 not found. Please install Python 3.6+ first."
    exit 1
fi
echo "✅ Python 3 found"

# Check Claude CLI
if ! command_exists claude; then
    echo "❌ Claude CLI not found."
    echo "   Please install from: https://docs.anthropic.com/en/docs/claude-code"
    if prompt_user "Continue without Claude CLI (you can install it later)?"; then
        echo "⚠️  Claude CLI missing - some features won't work until installed"
    else
        exit 1
    fi
else
    echo "✅ Claude CLI found"
fi

# Check for display server (for notifications)
if [[ -z "$DISPLAY" ]]; then
    echo "⚠️  No display server detected - notifications may not work"
else
    echo "✅ Display server available"
fi

echo ""
echo "📂 Setting up directories..."

# Create required directories
mkdir -p "$VAULT_DIR"
mkdir -p "$TOPICS_DIR" 
mkdir -p "$LOGS_DIR"
mkdir -p "$PROMPTS_DIR"

echo "✅ Created Obsidian vault structure at: $VAULT_DIR"

# Make all scripts executable
echo ""
echo "🔐 Making scripts executable..."
find "$PROJECT_DIR" -name "*.sh" -exec chmod +x {} \;
echo "✅ All scripts are now executable"

# Initialize empty files that might be referenced
echo ""
echo "📄 Creating initial files..."

# Create initial Biography.md if it doesn't exist
if [[ ! -f "$BIOGRAPHY_FILE" ]]; then
    cat > "$BIOGRAPHY_FILE" << 'EOF'
# Biography Q&A System

*A comprehensive personal knowledge base built through systematic questioning*

## How It Works
This system captures your life story through targeted questions, organized by topic areas for deep exploration of different life dimensions.

## Status
- **Setup**: ✅ Complete
- **Initial Questions**: Run `./setup/bootstrap-questions.sh` to get started
- **Mission Statement**: Run `./setup/mission-statement-builder.sh` after answering initial questions

## Topics Directory

*Topic areas will be automatically created as you answer questions*

## Links
- [[Mission Statement]] - Your personal mission and values
- [[ADHD-Tasks]] - Current prioritized task list
- [[Covey-Life-Analysis]] - Effectiveness assessment

#biography #personal-development #ai-powered
EOF
    echo "✅ Created initial Biography.md"
fi

# Create Priority Management template in vault if it doesn't exist
if [[ ! -f "$VAULT_DIR/Priority-Management.md" ]]; then
    cp "$PROJECT_DIR/templates/Priority-Management.md" "$VAULT_DIR/Priority-Management.md"
    echo "✅ Created Priority Management template"
fi

echo ""
echo "🎯 Setup Summary"
echo "================"
echo "Project Directory: $PROJECT_DIR"
echo "Obsidian Vault:    $VAULT_DIR"
echo "Topics Directory:  $TOPICS_DIR"
echo "Logs Directory:    $LOGS_DIR"

echo ""
echo "🚀 Next Steps - Getting Started:"
echo "1. Generate initial questions:"
echo "   cd $PROJECT_DIR && ./setup/bootstrap-questions.sh"
echo ""
echo "2. Answer 5-10 questions via notifications"
echo ""
echo "3. Create your mission statement:"
echo "   ./setup/mission-statement-builder.sh" 
echo ""
echo "4. Set up automation (optional):"
echo "   crontab -e"
echo "   # Add the schedule from README.md"
echo ""
echo "5. Open your Obsidian vault:"
echo "   Open Obsidian -> Open folder as vault -> $VAULT_DIR"

echo ""
echo "📚 Documentation:"
echo "• README.md - Complete documentation"  
echo "• Topic management: ./utils/topic-manager.sh --help"
echo "• Manual question generation: ./tasks/biography-questions.sh"

echo ""
if prompt_user "Would you like to run the bootstrap questions now?"; then
    echo ""
    exec "$PROJECT_DIR/setup/bootstrap-questions.sh"
else
    echo "✅ Installation complete! Run bootstrap-questions.sh when ready to start."
fi