# Biography Q&A Automation System

A comprehensive personal development and biography collection system that uses AI-powered analysis to build life narratives, track progress, and provide actionable insights through Stephen Covey's effectiveness principles.

## Features

### 📚 Biography Collection
- **Automated Q&A Generation**: AI generates contextual yes/no questions based on existing responses
- **Interactive Notifications**: GTK-based notifications for seamless question answering
- **Topic Organization**: Automatic routing to specialized topic areas (Career, Relationships, etc.)
- **Narrative Generation**: Converts Q&A data into coherent life stories

### 📊 Covey Analysis System
- **Monthly Comprehensive Analysis**: Full 7 Habits assessment and 4-week development plan
- **Weekly Progress Reviews**: Lightweight check-ins with targeted improvement questions
- **Progress Tracking**: Checkbox parsing and completion rate monitoring
- **Interactive Progress Questions**: Custom notification system for binary feedback

### ✅ Task Management
- **ADHD-Friendly Task Lists**: Time-bounded, specific actions with priority levels
- **Daily Refreshes**: Morning task list updates based on current priorities
- **Integration with Analysis**: Tasks aligned with Covey insights and biography goals

### 📈 Daily Summaries
- **Automated Reports**: End-of-day summaries for reflection and planning
- **Pattern Recognition**: Identifies trends and insights from collected data
- **Structured Logging**: Consistent format for historical analysis

## Directory Structure

```
biography/
├── tasks/                     # Cron job scripts
│   ├── biography-questions.sh      # Generates and asks biography questions
│   ├── covey-analysis-simple.sh    # Monthly comprehensive Covey analysis
│   ├── covey-weekly-review.sh      # Weekly progress reviews
│   ├── adhd-task-prioritizer.sh    # Daily task list generation
│   └── daily-summary-wrapper.sh    # End-of-day summary creation
├── utils/                     # Shared utilities and libraries
│   ├── auto-config.sh              # Centralized configuration management
│   ├── auto_config.py              # Python configuration module
│   ├── claude-wrapper.sh           # Claude AI integration wrapper
│   ├── biography-notification.py   # Biography Q&A notifications
│   ├── progress-notification.py    # Progress tracking notifications
│   ├── progress-questioner.sh      # Progress question presenter
│   ├── extract-qa-data.py          # Q&A data parsing utilities
│   ├── topic-manager.sh            # Topic creation and management
│   ├── extract-new-topics.sh       # Topic extraction from analysis
│   ├── daily-summary.py            # Daily summary generation
│   ├── generate-narrative.sh       # Narrative creation from Q&A data
│   └── batch-questions.py          # Bulk question generation
└── prompts/                   # AI agent instructions
    ├── stephen-covey-instructions.md   # Covey analysis agent prompt
    └── biography_instructions.md       # Biography collection agent prompt
```

## Installation & Setup

### Prerequisites
- **Python 3.6+** with packages: `gi` (GTK notifications)
- **Claude AI CLI** - [Installation Guide](https://docs.anthropic.com/en/docs/claude-code)
- **Linux/Unix environment** with cron support
- **Display server** for GTK notifications
- **Obsidian** (recommended) - Scripts generate markdown with Obsidian-style links `[[Topic]]` and tags `#covey #effectiveness`. Works with any markdown editor but optimized for Obsidian's linking system.

### Configuration

The system uses centralized configuration via environment variables:

```bash
# Default paths (can be overridden)
export VAULT_DIR="$HOME/Documents/Obsidian Vault"
export SCRIPTS_DIR="/home/rozar/biography" 
export LOGS_DIR="/home/rozar/logs"
export CLAUDE_PATH="claude"
```

Configuration is automatically loaded by all scripts through `utils/auto-config.sh`.

### Cron Schedule

Add to crontab (`crontab -e`):

```bash
# Biography questions every 30 minutes
*/30 * * * * /home/rozar/biography/tasks/biography-questions.sh

# Daily morning ADHD task refresh
0 7 * * * /home/rozar/biography/tasks/adhd-task-prioritizer.sh

# Daily summary generation (weekdays at 5:30 PM)
30 17 * * 1-5 /home/rozar/biography/tasks/daily-summary-wrapper.sh

# Monthly comprehensive Covey analysis (1st of month at 6 PM)
0 18 1 * * /home/rozar/biography/tasks/covey-analysis-simple.sh

# Weekly Covey progress review (Sundays at 6 PM, except 1st of month)
0 18 * * 0 /home/rozar/biography/tasks/covey-weekly-review.sh
```

## Usage

### Manual Execution

```bash
# Generate biography questions
./tasks/biography-questions.sh

# Run Covey analysis
./tasks/covey-analysis-simple.sh

# Create ADHD task list
./tasks/adhd-task-prioritizer.sh

# Generate daily summary
./utils/daily-summary.py create

# Ask progress questions
./utils/progress-questioner.sh
```

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

The system follows a modular architecture:

1. **Data Collection** (biography-questions.sh) → **Storage** (Obsidian Vault)
2. **Analysis** (covey-analysis-simple.sh) → **Insights** (Covey-Life-Analysis.md)
3. **Progress Tracking** (covey-weekly-review.sh) → **Course Corrections**
4. **Task Generation** (adhd-task-prioritizer.sh) → **Actionable Items**
5. **Daily Synthesis** (daily-summary.py) → **Reflection & Planning**

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