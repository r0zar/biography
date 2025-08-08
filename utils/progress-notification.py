#!/usr/bin/python3
import os
import sys
import re
import subprocess
from datetime import datetime

# Auto-load configuration
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from auto_config import VAULT_DIR, LOGS_DIR

# Set environment for cron
os.environ['DISPLAY'] = ':1'


class ProgressNotifier:
    def __init__(self, question, positive_label="Good", negative_label="Poor"):
        self.question = question
        self.positive_label = positive_label
        self.negative_label = negative_label
        self.log_file = os.path.join(LOGS_DIR, 'progress-responses.log')

    def log(self, message):
        """Log progress responses and actions"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        with open(self.log_file, "a") as f:
            f.write(f"{timestamp}: {message}\n")

    def record_response(self, response):
        """Record progress response to log file"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        week_of = datetime.now().strftime('%Y-W%U')  # Week format: 2025-W32
        
        log_entry = f"{timestamp} | {week_of} | {self.question} | {response}"
        
        with open(self.log_file, "a") as f:
            f.write(f"{log_entry}\n")
            
        self.log(f"Recorded progress response: {response}")

    def show_notification(self):
        """Show progress question using Zenity dialog"""
        try:
            # Use zenity question dialog with custom buttons
            result = subprocess.run([
                'zenity', '--question',
                '--title=📊 Weekly Progress Check',
                f'--text={self.question}',
                f'--ok-label=✅ {self.positive_label}',
                f'--cancel-label=❌ {self.negative_label}',
                '--width=600',
                '--height=200'
            ], capture_output=True, text=True)
            
            # Handle response based on return code
            if result.returncode == 0:
                # Positive button clicked
                self.log(f"User selected: {self.positive_label}")
                self.record_response(self.positive_label)
            elif result.returncode == 1:
                # Negative button clicked  
                self.log(f"User selected: {self.negative_label}")
                self.record_response(self.negative_label)
            else:
                # Dialog was cancelled or closed
                self.log("Progress dialog cancelled/closed without response")
                return False
                
            return True
            
        except Exception as e:
            self.log(f"Error showing progress notification: {e}")
            return False


def ask_progress_question(question, positive_label="Good", negative_label="Poor"):
    """Convenience function to ask a single progress question"""
    notifier = ProgressNotifier(question, positive_label, negative_label)
    return notifier.show_notification()


def main():
    """CLI interface for progress notifications"""
    if len(sys.argv) < 2:
        print("Usage: progress-notification.py 'Question text?' [positive_label] [negative_label]")
        print("Example: progress-notification.py 'Job search consistency this week?' 'Strong' 'Weak'")
        sys.exit(1)
    
    question = sys.argv[1]
    positive_label = sys.argv[2] if len(sys.argv) > 2 else "Good"
    negative_label = sys.argv[3] if len(sys.argv) > 3 else "Poor"
    
    ask_progress_question(question, positive_label, negative_label)


if __name__ == "__main__":
    main()