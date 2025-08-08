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
                            
                            # Look for the question (with or without custom labels) - match both ❌ and ⏳
                            pattern = rf'^- [❌⏳] {re.escape(self.question)}.*?(\[.*?\])?(\s*\*.*\*)?$'
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
                                elif status == "pending":
                                    new_line = f"- ⏳ {self.question} *(asked {timestamp})*"
                                elif status == "unanswered":
                                    new_line = f"- ❌ {self.question}"
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

            # Find and update the FIRST occurrence of the question - match both ❌ and ⏳
            old_pattern_unanswered = f"- ❌ {self.question}"
            old_pattern_pending = f"- ⏳ {self.question}"

            if status == "yes":
                new_line = f"- ✅ {self.question}\n  **Answer:** {answer} *(answered {timestamp})*"
            elif status == "no":
                new_line = f"- ✅ {self.question}\n  **Answer:** No *(answered {timestamp})*"
            elif status == "skip":
                new_line = f"- ⏭ {self.question} *(skipped {timestamp})*"
            elif status == "pending":
                new_line = f"- ⏳ {self.question} *(asked {timestamp})*"
            elif status == "unanswered":
                new_line = f"- ❌ {self.question}"
            else:
                new_line = f"- ⏳ {self.question} *(asked {timestamp})*"

            # Try to replace either pattern
            if old_pattern_unanswered in content:
                updated_content = content.replace(old_pattern_unanswered, new_line, 1)
            elif old_pattern_pending in content:
                # Replace pending questions including timestamp
                import re
                pending_pattern = rf"- ⏳ {re.escape(self.question)}.*?(\*.*\*)?"
                updated_content = re.sub(pending_pattern, new_line, content, count=1)
            else:
                self.log(f"Fallback: Could not find question pattern: {self.question}")
                return

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

    def handle_timeout(self):
        """Handle timeout or dismissal - revert pending question back to unanswered"""
        self.update_question_status("unanswered")
        self.log(f"Question timed out or was dismissed, reverted to unanswered: {self.question}")
        
        if self.loop:
            self.loop.quit()
            
        return False  # Don't repeat the timeout

    def send_question(self):
        """Send the biography question with Yes/No/Skip buttons"""
        try:
            # First, mark the question as pending (⏳) before asking
            self.update_question_status("pending")
            self.log(f"Marked question as pending: {self.question}")
            
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
            GLib.timeout_add_seconds(300, self.handle_timeout)  # 5 minute timeout

            try:
                self.loop.run()
            except KeyboardInterrupt:
                self.log("Biography question interrupted")
                self.handle_timeout()  # Also revert on interrupt

        except Exception as e:
            self.log(f"Error sending biography question: {e}")
            # If there's an error, revert the question back to unanswered
            self.update_question_status("unanswered")


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
        
        # First check for any pending questions (⏳) - if any exist, present them instead of asking new ones
        for filepath in files_to_search:
            if not os.path.exists(filepath):
                continue
                
            try:
                with open(filepath, 'r') as f:
                    content = f.read()
                
                lines = content.split('\n')
                for line in lines:
                    if line.strip().startswith('- ⏳'):
                        # Found a pending question - extract it and present it
                        question_line = line.strip()[4:].strip()  # Remove "- ⏳ "
                        
                        # Remove timestamp if present
                        if '*(asked ' in question_line:
                            question_line = question_line.split('*(asked ')[0].strip()
                        
                        # Parse custom button labels if they exist
                        yes_label, no_label = "Yes", "No"  # defaults
                        if '[' in question_line and ']' in question_line:
                            label_start = question_line.rfind('[')
                            label_end = question_line.rfind(']')
                            
                            if label_start < label_end:
                                label_section = question_line[label_start+1:label_end]
                                clean_question = question_line[:label_start].strip()
                                
                                # Parse Yes=Label1|No=Label2 format
                                if '|' in label_section:
                                    parts = label_section.split('|')
                                    for part in parts:
                                        part = part.strip()
                                        if part.startswith('Yes='):
                                            yes_label = part[4:].strip()
                                        elif part.startswith('No='):
                                            no_label = part[3:].strip()
                                
                                return clean_question, 1, yes_label, no_label
                        
                        return question_line, 1, yes_label, no_label
                        
            except Exception as e:
                continue  # Skip files that can't be read
        
        # No pending questions found, search for unanswered questions with intelligent prioritization
        
        # Try to load Priority Management file for priority guidance
        priority_topics = []
        priority_file = os.path.join(vault_dir, "Priority-Management.md")
        if os.path.exists(priority_file):
            try:
                with open(priority_file, 'r') as f:
                    priority_content = f.read()
                
                # Extract priority topic areas from the file
                # Look for key patterns that indicate high priority areas
                if "Job Application" in priority_content or "job search" in priority_content.lower():
                    priority_topics.append("Job Search Strategy")
                if "Morning" in priority_content and "discipline" in priority_content.lower():
                    priority_topics.append("Personal Effectiveness")
                if "Interview" in priority_content and ("confidence" in priority_content.lower() or "stress" in priority_content.lower()):
                    priority_topics.append("Interview Performance")
                if "Career" in priority_content and "transition" in priority_content.lower():
                    priority_topics.append("Career Transition")
                if "Family" in priority_content or "Niccaela" in priority_content:
                    priority_topics.append("Family Relationships")
                    
            except Exception as e:
                pass  # Fall back to alphabetical if priority file can't be read
        
        # Collect all unanswered questions with their file paths
        all_questions = []
        
        for filepath in files_to_search:
            if not os.path.exists(filepath):
                continue
                
            try:
                with open(filepath, 'r') as f:
                    content = f.read()
                
                lines = content.split('\n')
                filename = os.path.basename(filepath)
                topic_name = filename.replace('.md', '') if filename.endswith('.md') else filename
                
                for line in lines:
                    if line.strip().startswith('- ❌') and len(line.strip()) > 4:
                        question_count += 1
                        question = line.strip()[4:].strip()  # Remove "- ❌ "
                        if question and question != "Not asked yet":  # Make sure we have actual question text

                            # Parse custom button labels if they exist
                            yes_label, no_label = "Yes", "No"  # defaults
                            clean_question = question

                            # Check for custom labels in square brackets
                            if '[' in question and ']' in question:
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

                            # Add to collection with priority score
                            priority_score = 0
                            if topic_name in priority_topics:
                                priority_score = len(priority_topics) - priority_topics.index(topic_name)  # Higher score for earlier topics
                            
                            all_questions.append((clean_question, question_count, yes_label, no_label, priority_score, topic_name))
                            
            except Exception as e:
                continue  # Skip files that can't be read
        
        # Sort questions by priority score (highest first), then by original order
        if all_questions:
            all_questions.sort(key=lambda x: (-x[4], x[1]))  # Sort by -priority_score, then by question_count
            # Return the highest priority question
            best_question = all_questions[0]
            return best_question[0], best_question[1], best_question[2], best_question[3]

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
    parser.add_argument('--check-pending-only', action='store_true',
                        help='Only check for pending questions, don\'t ask new ones (exit code 1 if pending found)')
    args = parser.parse_args()

    # Log script execution
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(os.path.join(LOGS_DIR, 'biography-responses.log'), "a") as f:
        f.write(f"{timestamp}: Biography notification script started\n")

    # Handle check-pending-only mode
    if args.check_pending_only:
        # Check if there are any pending questions
        vault_dir = VAULT_DIR
        topics_dir = os.path.join(vault_dir, "Topics")
        
        files_to_search = [os.path.join(vault_dir, "Biography.md")]
        if os.path.exists(topics_dir):
            for filename in os.listdir(topics_dir):
                if filename.endswith('.md'):
                    files_to_search.append(os.path.join(topics_dir, filename))
        
        for filepath in files_to_search:
            if not os.path.exists(filepath):
                continue
                
            try:
                with open(filepath, 'r') as f:
                    content = f.read()
                
                lines = content.split('\n')
                for line in lines:
                    if line.strip().startswith('- ⏳'):
                        # Found a pending question - exit with code 1
                        with open(os.path.join(LOGS_DIR, 'biography-responses.log'), "a") as f:
                            f.write(f"{timestamp}: Check-pending-only: Found pending question, exiting with code 1\n")
                        exit(1)
                        
            except Exception as e:
                continue
        
        # No pending questions found - exit with code 0
        with open(os.path.join(LOGS_DIR, 'biography-responses.log'), "a") as f:
            f.write(f"{timestamp}: Check-pending-only: No pending questions found, exiting with code 0\n")
        exit(0)

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
