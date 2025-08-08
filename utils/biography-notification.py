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
from auto_config import VAULT_DIR, LOGS_DIR, BIOGRAPHY_FILE

# Set environment for cron
os.environ['DISPLAY'] = ':1'
if 'DBUS_SESSION_BUS_ADDRESS' not in os.environ:
    os.environ['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=/run/user/1000/bus'


class BiographyNotifier:
    def __init__(self, question, question_id, yes_label="Yes", no_label="No"):
        Notify.init("BiographyBot")
        self.question = question
        self.question_id = question_id
        self.yes_label = yes_label
        self.no_label = no_label
        self.loop = None
        self.biography_file = BIOGRAPHY_FILE
        self.log_file = os.path.join(LOGS_DIR, 'biography-responses.log')

    def log(self, message):
        """Log responses and actions"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        with open(self.log_file, "a") as f:
            f.write(f"{timestamp}: {message}\n")

    def update_question_status(self, status, answer=None):
        """Update the question status using direct Python replacement"""
        try:
            self._python_update(status, answer)
        except Exception as e:
            self.log(f"Python update failed, trying fallback: {e}")
            # Try fallback method
            self._fallback_update(status, answer)

    def _python_update(self, status, answer=None):
        """Update question status using Python for reliable text replacement"""
        import re
        import os
        
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        # Search all markdown files for the question
        vault_dir = VAULT_DIR
        search_dirs = [vault_dir, os.path.join(vault_dir, "Topics")]
        
        for search_dir in search_dirs:
            if not os.path.exists(search_dir):
                continue
                
            for root, dirs, files in os.walk(search_dir):
                for file in files:
                    if file.endswith('.md'):
                        filepath = os.path.join(root, file)
                        
                        try:
                            with open(filepath, 'r', encoding='utf-8') as f:
                                content = f.read()
                            
                            # Look for the question (with or without custom labels)
                            pattern = rf'^- ❌ {re.escape(self.question)}.*?(\[.*?\])?$'
                            if re.search(pattern, content, re.MULTILINE):
                                # Create replacement text
                                if status == "yes":
                                    if answer:
                                        new_line = f"- ✅ {self.question}\n  **Answer:** {answer} *(answered {timestamp})*"
                                    else:
                                        new_line = f"- ✅ {self.question}\n  **Answer:** Yes *(answered {timestamp})*"
                                elif status == "no":
                                    new_line = f"- ✅ {self.question}\n  **Answer:** No *(answered {timestamp})*"
                                elif status == "skip":
                                    new_line = f"- ⏭ {self.question} *(skipped {timestamp})*"
                                else:
                                    new_line = f"- ⏳ {self.question} *(asked {timestamp})*"
                                
                                # Replace the question
                                updated_content = re.sub(pattern, new_line, content, count=1, flags=re.MULTILINE)
                                
                                # Write back to file
                                with open(filepath, 'w', encoding='utf-8') as f:
                                    f.write(updated_content)
                                
                                self.log(f"Python update: Updated question status to {status}: {self.question}")
                                return
                                
                        except Exception as e:
                            continue
        
        # If we get here, question wasn't found
        self.log(f"Python update: Question not found in any file: {self.question}")

    def _fallback_update(self, status, answer=None):
        """Fallback method to update Biography.md directly"""
        try:
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

            with open(self.biography_file, 'r') as f:
                content = f.read()

            # Find and update the FIRST occurrence of the question
            old_pattern = f"- ❌ {self.question}"

            if status == "yes":
                new_line = f"- ✅ {self.question}\n  **Answer:** {answer} *(answered {timestamp})*"
            elif status == "no":
                new_line = f"- ✅ {self.question}\n  **Answer:** No *(answered {timestamp})*"
            elif status == "skip":
                new_line = f"- ⏭ {self.question} *(skipped {timestamp})*"
            else:
                new_line = f"- ⏳ {self.question} *(asked {timestamp})*"

            # Replace only the FIRST occurrence
            updated_content = content.replace(old_pattern, new_line, 1)

            with open(self.biography_file, 'w') as f:
                f.write(updated_content)

            self.log(
                f"Fallback: Updated question status to {status}: {self.question}")

        except Exception as e:
            self.log(f"Fallback update failed: {e}")

    def handle_yes(self, notification, action, data):
        """Handle Yes response"""
        self.update_question_status("yes", self.yes_label)
        self.log(f"User answered '{self.yes_label}' to: {self.question}")

        if self.loop:
            self.loop.quit()

    def handle_no(self, notification, action, data):
        """Handle No response"""
        self.update_question_status("no", self.no_label)
        self.log(f"User answered '{self.no_label}' to: {self.question}")

        if self.loop:
            self.loop.quit()

    def handle_skip(self, notification, action, data):
        """Handle Skip response"""
        self.update_question_status("skip")
        self.log(f"User SKIPPED question: {self.question}")

        if self.loop:
            self.loop.quit()

    def send_question(self):
        """Send the biography question with Yes/No/Skip buttons"""
        try:
            notice = Notify.Notification.new(
                f"📖 Biography Question",
                f"{self.question}\n",
                "dialog-question"
            )
            notice.set_timeout(0)  # Never expire (0 = never)
            notice.set_urgency(Notify.Urgency.NORMAL)

            # Add action buttons with custom labels
            notice.add_action(
                "yes", f"✅ {self.yes_label}", self.handle_yes, None)
            notice.add_action("no", f"❌ {self.no_label}", self.handle_no, None)
            notice.add_action("skip", "⏭ Skip", self.handle_skip, None)

            result = notice.show()
            self.log(f"Biography question sent: {self.question}")

            # Keep alive for user interaction (max 5 minutes)
            self.loop = GLib.MainLoop()
            GLib.timeout_add_seconds(300, self.loop.quit)  # 5 minute timeout

            try:
                self.loop.run()
            except KeyboardInterrupt:
                self.log("Biography question interrupted")

        except Exception as e:
            self.log(f"Error sending biography question: {e}")


def find_next_question():
    """Find the next unanswered question from biography file and all topic files"""
    import os
    
    try:
        vault_dir = VAULT_DIR
        topics_dir = os.path.join(vault_dir, "Topics")
        
        # List of files to search - Biography.md first, then all topic files
        files_to_search = [os.path.join(vault_dir, "Biography.md")]
        
        # Add all topic files
        if os.path.exists(topics_dir):
            for filename in os.listdir(topics_dir):
                if filename.endswith('.md'):
                    files_to_search.append(os.path.join(topics_dir, filename))
        
        question_count = 0
        
        # Search each file for unanswered questions
        for filepath in files_to_search:
            if not os.path.exists(filepath):
                continue
                
            try:
                with open(filepath, 'r') as f:
                    content = f.read()
                
                lines = content.split('\n')
                
                for line in lines:
                    if line.strip().startswith('- ❌') and len(line.strip()) > 4:
                        question_count += 1
                        question = line.strip()[4:].strip()  # Remove "- ❌ "
                        if question and question != "Not asked yet":  # Make sure we have actual question text

                            # Parse custom button labels if they exist
                            # Format: "Question text? [Yes=Custom1|No=Custom2]"
                            yes_label, no_label = "Yes", "No"  # defaults

                            # Check for custom labels in square brackets
                            if '[' in question and ']' in question:
                                # Extract the labels and the clean question
                                label_start = question.rfind('[')
                                label_end = question.rfind(']')

                                if label_start < label_end:
                                    label_section = question[label_start+1:label_end]
                                    clean_question = question[:label_start].strip()

                                    # Parse Yes=Label1|No=Label2 format
                                    if '|' in label_section:
                                        parts = label_section.split('|')
                                        for part in parts:
                                            part = part.strip()
                                            if part.startswith('Yes='):
                                                yes_label = part[4:].strip()
                                            elif part.startswith('No='):
                                                no_label = part[3:].strip()

                                    return clean_question, question_count, yes_label, no_label

                            return question, question_count, yes_label, no_label
                            
            except Exception as e:
                continue  # Skip files that can't be read

        return None, 0, "Yes", "No"

    except Exception as e:
        print(f"Error searching for questions: {e}")
        return None, 0, "Yes", "No"


if __name__ == "__main__":
    import argparse

    # Parse command line arguments for custom labels
    parser = argparse.ArgumentParser(
        description='Send biography question with custom button labels')
    parser.add_argument('--question', '-q', type=str,
                        help='Specific question to ask')
    parser.add_argument('--yes-label', '-y', type=str,
                        default='Yes', help='Custom label for yes button')
    parser.add_argument('--no-label', '-n', type=str,
                        default='No', help='Custom label for no button')
    args = parser.parse_args()

    # Log script execution
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(os.path.join(LOGS_DIR, 'biography-responses.log'), "a") as f:
        f.write(f"{timestamp}: Biography notification script started\n")

    if args.question:
        # Use provided question and labels
        question = args.question
        question_id = 1  # Default ID for manual questions
        yes_label = args.yes_label
        no_label = args.no_label

        with open(os.path.join(LOGS_DIR, 'biography-responses.log'), "a") as f:
            f.write(f"{timestamp}: Using provided question: {question}\n")
    else:
        # Find next question automatically
        question, question_id, yes_label, no_label = find_next_question()

    if question:
        with open(os.path.join(LOGS_DIR, 'biography-responses.log'), "a") as f:
            f.write(
                f"{timestamp}: Found question to ask: {question} (Yes='{yes_label}', No='{no_label}')\n")

        notifier = BiographyNotifier(
            question, question_id, yes_label, no_label)
        notifier.send_question()
    else:
        # All questions answered, log completion
        with open(os.path.join(LOGS_DIR, 'biography-responses.log'), "a") as f:
            f.write(f"{timestamp}: No unanswered questions found\n")
