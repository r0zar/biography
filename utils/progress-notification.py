#!/usr/bin/python3
import gi
gi.require_version('Notify', '0.7')
from gi.repository import Notify, GLib
import os
import sys
import re
from datetime import datetime

# Auto-load configuration
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from auto_config import VAULT_DIR, LOGS_DIR

# Set environment for cron
os.environ['DISPLAY'] = ':1'
if 'DBUS_SESSION_BUS_ADDRESS' not in os.environ:
    os.environ['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=/run/user/1000/bus'


class ProgressNotifier:
    def __init__(self, question, positive_label="Good", negative_label="Poor"):
        Notify.init("CoveyProgressBot")
        self.question = question
        self.positive_label = positive_label
        self.negative_label = negative_label
        self.loop = None
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

    def on_positive_clicked(self, notification, action, data):
        """Handle positive response (Good/Strong/Better/etc.)"""
        self.log(f"User selected: {self.positive_label}")
        self.record_response(self.positive_label)
        notification.close()
        if self.loop:
            self.loop.quit()

    def on_negative_clicked(self, notification, action, data):
        """Handle negative response (Poor/Weak/Worse/etc.)"""
        self.log(f"User selected: {self.negative_label}")
        self.record_response(self.negative_label)
        notification.close()
        if self.loop:
            self.loop.quit()

    def on_closed(self, notification):
        """Handle notification closed without response"""
        self.log("Progress notification closed without response")
        if self.loop:
            self.loop.quit()

    def show_notification(self):
        """Show progress question notification with custom buttons"""
        try:
            notification = Notify.Notification.new(
                "Weekly Progress Check",
                self.question,
                "dialog-question"
            )
            
            # Set longer timeout for progress questions
            notification.set_timeout(30000)  # 30 seconds
            
            # Add custom action buttons
            notification.add_action(
                "positive",
                self.positive_label,
                self.on_positive_clicked,
                None
            )
            
            notification.add_action(
                "negative", 
                self.negative_label,
                self.on_negative_clicked,
                None
            )
            
            notification.connect("closed", self.on_closed)
            notification.show()
            
            # Run event loop to wait for response
            self.loop = GLib.MainLoop()
            self.loop.run()
            
        except Exception as e:
            self.log(f"Error showing progress notification: {e}")
            return False
            
        return True


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