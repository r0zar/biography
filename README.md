# Biography Q&A Automation System

A comprehensive personal development and biography collection system that uses Claude AI to build life narratives, track progress, and provide actionable insights through Stephen Covey's effectiveness principles and Greg McKeown's Essentialism framework.

## Features

### 📚 Biography Collection
- **Claude-Powered Q&A Generation**: Intelligent contextual questions using Essentialism principles
- **Smart Topic Routing**: Automatic question routing to specialized topic areas with Obsidian integration
- **Interactive Notifications**: Lightweight notifications with action buttons for seamless answering
- **Topic Consolidation**: Intelligent merging of similar Q&As into information-rich insights
- **Narrative Generation**: Converts Q&A data into coherent life stories

### 📊 Covey Analysis System
- **Monthly Comprehensive Analysis**: Full 7 Habits assessment and 4-week development plan
- **Weekly Progress Reviews**: Lightweight check-ins with targeted improvement questions
- **Progress Tracking**: Checkbox parsing and completion rate monitoring
- **ADHD Task Integration**: Tasks aligned with current priority areas and completion rates

### 🧠 Intelligent Topic Management
- **Claude-Powered Routing**: Smart question placement across topic areas
- **Obsidian Integration**: Auto-tagging, cross-linking, and hierarchical organization
- **Smart Consolidation**: Merges redundant Q&As into comprehensive, actionable insights
- **Metadata Management**: Analytics, completion tracking, and relationship mapping

### ✅ Task Management
- **Essentialist Task Lists**: Focus on vital few priorities with time-bounded actions
- **Morning Discipline**: Priority-setting before reactive message checking
- **Integration with Analysis**: Tasks aligned with Covey insights and biography goals

### 📈 Daily Summaries
- **Automated Reports**: End-of-day summaries for reflection and planning
- **Pattern Recognition**: Identifies trends and insights from collected data
- **Structured Logging**: Consistent format for historical analysis

## Directory Structure

```
biography/
├── tasks/                     # Cron job scripts
│   ├── biography-questions.sh      # Claude-powered essentialist question prioritization
│   ├── covey-analysis-simple.sh    # Monthly comprehensive Covey analysis
│   ├── covey-weekly-review.sh      # Weekly progress reviews  
│   ├── adhd-task-prioritizer.sh    # Daily task list generation
│   └── daily-summary-wrapper.sh    # End-of-day summary creation
├── utils/                     # Shared utilities and libraries
│   ├── auto-config.sh              # Centralized configuration management
│   ├── auto_config.py              # Python configuration module
│   ├── claude-wrapper.sh           # Claude AI integration wrapper
│   ├── topic-manager.sh            # Claude-powered topic routing & consolidation
│   ├── generate-questions.sh       # Intelligent question generation
│   ├── progress-notification.py    # Progress tracking notifications
│   ├── progress-questioner.sh      # Progress question presenter
│   ├── extract-qa-data.py          # Q&A data parsing utilities
│   ├── extract-new-topics.sh       # Topic extraction from analysis
│   ├── daily-summary.py            # Daily summary generation
│   └── generate-narrative.sh       # Narrative creation from Q&A data
├── templates/                 # System templates and formats
│   ├── Priority-Management.md       # Essentialism framework template
│   └── question-generation-format.md # Question formatting standards
├── prompts/                   # AI agent instructions
│   ├── stephen-covey-instructions.md     # Covey analysis agent prompt
│   └── greg-mckeown-essentialist-instructions.md # Essentialism agent prompt
└── setup/                     # Getting started scripts (created during setup)
    ├── bootstrap-questions.sh       # Initial question generation
    ├── mission-statement-builder.sh # Guided mission creation
    └── install.sh                   # One-command setup script
```

## Installation & Setup

### Quick Start (One Command)

```bash
# Clone and setup in one command
cd $HOME && git clone [repository-url] biography && cd biography && ./setup/install.sh
```

### Prerequisites
- **Python 3.6+** with packages: `gi` (GTK notifications)
- **Claude AI CLI** - [Installation Guide](https://docs.anthropic.com/en/docs/claude-code)
- **Linux/Unix environment** with cron support
- **Display server** for GTK notifications
- **Obsidian** (recommended) - Scripts generate markdown with Obsidian-style links `[[Topic]]` and tags `#covey #effectiveness`. Works with any markdown editor but optimized for Obsidian's linking system.

### Manual Installation

```bash
# 1. Clone repository to home directory
cd $HOME
git clone [repository-url] biography
cd biography

# 2. Make scripts executable
chmod +x **/*.sh

# 3. Run initial setup
./setup/install.sh
```

### Configuration

The system uses centralized configuration via environment variables:

```bash
# Default paths (automatically configured)
export VAULT_DIR="$HOME/Documents/Obsidian Vault"
export SCRIPTS_DIR="$HOME/biography" 
export LOGS_DIR="$HOME/biography/logs"
export CLAUDE_PATH="claude"
```

Configuration is automatically loaded by all scripts through `utils/auto-config.sh`.

### Automated Cron Schedule

The install script automatically configures cron jobs. Manual configuration:

```bash
# Biography questions every 30 minutes (essentialist prioritization)
*/30 * * * * $HOME/biography/tasks/biography-questions.sh

# Daily morning ADHD task refresh
0 7 * * * $HOME/biography/tasks/adhd-task-prioritizer.sh

# Daily summary generation (weekdays at 5:30 PM)
30 17 * * 1-5 $HOME/biography/tasks/daily-summary-wrapper.sh

# Monthly comprehensive Covey analysis (1st of month at 6 PM)
0 18 1 * * $HOME/biography/tasks/covey-analysis-simple.sh

# Weekly Covey progress review (Sundays at 6 PM, except 1st of month)  
0 18 * * 0 $HOME/biography/tasks/covey-weekly-review.sh
```

## Getting Started (New User Guide)

### Phase 1: Initial Setup
After installation, the system starts with an empty Obsidian vault. The setup process guides you through building a foundation.

### Phase 2: Bootstrap Questions
```bash
# Generate initial questions across key life areas
./setup/bootstrap-questions.sh
```
This creates 10-15 diverse questions covering:
- Career transition and goals
- Personal effectiveness and habits  
- Relationships and family
- Personal identity and values
- Financial planning

### Phase 3: Answer Foundation Questions
The system presents questions via notifications. Answer 5-10 questions to build initial context data.

### Phase 4: Mission Statement Creation
```bash
# Guided mission statement creation based on your responses
./setup/mission-statement-builder.sh
```
Claude analyzes your answers and guides you through creating a comprehensive mission statement.

### Phase 5: System Activation
After answering foundation questions and creating your mission statement, the system becomes self-sustaining:
- **30-minute questions**: Essentialist prioritization based on your context
- **Morning tasks**: ADHD-friendly priorities aligned with your mission
- **Weekly reviews**: Progress tracking and course corrections
- **Monthly analysis**: Comprehensive Covey 7 Habits assessment

### Ready to Use
Your system now has:
- ✅ Populated topic areas with initial Q&As
- ✅ Mission statement for priority alignment  
- ✅ Automated cron jobs for ongoing questions
- ✅ Context data for intelligent question generation
- ✅ Obsidian vault with cross-linked topics

## Usage

### Manual Execution

```bash
# Generate essentialist-prioritized biography questions
./tasks/biography-questions.sh

# Run comprehensive Covey analysis
./tasks/covey-analysis-simple.sh

# Create ADHD-focused task list
./tasks/adhd-task-prioritizer.sh

# Generate daily summary
./utils/daily-summary.py create

# Topic management (Claude-powered)
./utils/topic-manager.sh route-question "Your question here"
./utils/topic-manager.sh consolidate "Topic Name"
./utils/topic-manager.sh create "New Topic"

# Ask progress questions
./utils/progress-questioner.sh
```

### Topic Management System

The Claude-powered topic manager provides intelligent organization:

```bash
# Route questions to optimal topics
./utils/topic-manager.sh route-question "What are my biggest career obstacles?"

# Create new topic areas
./utils/topic-manager.sh create "Health and Wellness"

# Add questions to topics
./utils/topic-manager.sh add-question "Career Transition" "Have you updated your LinkedIn?"

# Update question status
./utils/topic-manager.sh update-status "question text" "✅" "answer text"

# Consolidate similar Q&As into insights
./utils/topic-manager.sh consolidate "Personal Effectiveness"
```

**Topic Manager Features:**
- **Intelligent Routing**: Claude determines optimal topic placement
- **Obsidian Integration**: Auto-tagging, cross-linking, metadata management
- **Smart Consolidation**: Merges redundant questions into comprehensive insights
- **Analytics**: Completion rates, activity tracking, relationship mapping

### Interactive Components

- **Biography Questions**: Appear as notifications every 30 minutes
- **Progress Questions**: Triggered after weekly Covey reviews
- **Task Management**: Checkbox-based progress tracking in generated files

## Output Files

All generated content goes to `$VAULT_DIR` as Obsidian-compatible markdown:

- `Biography.md` - Main biography Q&A collection
- `Topics/*.md` - Specialized topic areas with internal links
- `Covey-Life-Analysis.md` - Current monthly analysis with `[[Biography]]` links
- `Weekly-Covey-Review-[date].md` - Weekly progress reviews
- `ADHD-Tasks.md` - Current prioritized task list with checkboxes
- `[date].md` - Daily summary files

*Note: Files use Obsidian syntax (`[[Internal Links]]`, `#tags`) but work with any markdown editor.*

## Key Features

### Smart Question Generation
- Context-aware questions based on existing responses
- Follow-up questions for deeper exploration
- Binary (yes/no) format for easy notification responses

### Progress Measurement
- Checkbox completion rate tracking
- Targeted questions for underperforming areas
- Weekly trend analysis and course corrections

### Multi-Platform Configuration
- Environment variable overrides for portability
- Automatic path detection and configuration
- Session-based loading to prevent duplicates

### Covey Integration
- Full 7 Habits assessment framework
- Circle of Influence vs Circle of Concern analysis
- Time Management Matrix application
- Character-based development planning

## Development

### Adding New Scripts
1. Place in appropriate directory (`tasks/`, `utils/`)
2. Add auto-config loading: `source "$(dirname "$0")/../utils/auto-config.sh"`
3. Use environment variables for paths
4. Make executable: `chmod +x script-name.sh`

### Configuration Management
- All paths centralized in `utils/auto-config.sh`
- Python scripts import from `utils/auto_config.py`
- Override defaults with environment variables

### Logging
- Centralized logging to `$LOGS_DIR/`
- Structured format with timestamps
- Separate logs for each component

## Architecture

The system follows a Claude-powered modular architecture:

### Core Flow
1. **Essentialist Question Prioritization** → **Claude Analysis** → **Targeted Questions**
2. **Topic Management** → **Intelligent Routing** → **Organized Storage** (Obsidian Vault)
3. **Covey Analysis** → **Effectiveness Insights** → **ADHD Task Prioritization**
4. **Progress Tracking** → **Pattern Recognition** → **Course Corrections**
5. **Daily Synthesis** → **Narrative Generation** → **Reflection & Planning**

### Claude Integration Points
- **Question Generation**: Essentialist principles prioritize vital few questions
- **Topic Routing**: Intelligent placement and organization of Q&As
- **Consolidation**: Smart merging of similar questions into comprehensive insights
- **Analysis**: 7 Habits assessment and personalized development planning
- **Task Prioritization**: ADHD-friendly task lists aligned with current priorities

### Key Design Principles
- **Intelligence over Hardcoding**: Claude handles complex decision-making
- **Essentialism**: Focus on vital few priorities rather than reactive urgency
- **Context Awareness**: All components share centralized context and configuration
- **Obsidian Integration**: Rich cross-linking, tagging, and metadata management
- **Progressive Enhancement**: System becomes smarter as it learns more about you

## Troubleshooting

### Common Issues

**Notifications not appearing:**
- Check DISPLAY environment variable: `echo $DISPLAY`
- Ensure you're in a graphical session
- Test with: `notify-send "test" "message"`

**Claude CLI not found:**
- Install from: https://docs.anthropic.com/en/docs/claude-code
- Verify installation: `claude --version`
- Check PATH includes Claude CLI location

**Permission denied on scripts:**
- Make executable: `chmod +x **/*.sh`
- Check file permissions: `ls -la tasks/`

**Empty topic files:**
- Run bootstrap questions: `./setup/bootstrap-questions.sh`
- Check log files in `logs/` directory
- Verify Obsidian vault path in auto-config.sh

**Cron jobs not running:**
- Check cron service: `systemctl status cron`
- Verify crontab: `crontab -l`
- Check logs: `tail -f logs/*.log`
- Ensure full paths in crontab entries

### System Health Check

```bash
# Verify system configuration
./setup/verify-system.sh  # (if created)

# Check all components
ls -la $HOME/biography/tasks/*.sh
ls -la $HOME/Documents/Obsidian\ Vault/Topics/
tail -f $HOME/biography/logs/*.log
```

### Support

- Check logs in `logs/` directory for detailed error messages
- Review auto-config.sh for path configurations
- Test individual components manually before enabling automation

## Contributing

1. Fork the repository
2. Create feature branch
3. Follow existing code patterns
4. Test with sample data
5. Submit pull request

## License

This project is for personal development and biography collection. Customize paths and configuration for your environment.

---

*Built with Claude AI for automated personal development and life story collection.*