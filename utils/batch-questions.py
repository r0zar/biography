#!/usr/bin/python3
from gi.repository import Notify, GLib
import gi
import os
import sys
import re
from datetime import datetime
import time

# Auto-load configuration
from utils.auto_config import VAULT_DIR, LOGS_DIR

# Set environment for cron
os.environ['DISPLAY'] = ':1'
if 'DBUS_SESSION_BUS_ADDRESS' not in os.environ:
    os.environ['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=/run/user/1000/bus'

gi.require_version('Notify', '0.7')


class BatchQuestionNotifier:
    def __init__(self):
        Notify.init("BiographyBot")
        self.vault_dir = VAULT_DIR
        self.log_file = os.path.join(LOGS_DIR, 'biography-responses.log')
        self.current_question = None
        self.current_question_id = None
        self.yes_label = "Yes"
        self.no_label = "No"
        self.loop = None
        self.questions_answered = 0

    def log(self, message):
        """Log responses and actions"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        with open(self.log_file, "a") as f:
            f.write(f"{timestamp}: {message}\n")

    def find_unanswered_questions(self, limit=10):
        """Find up to 'limit' unanswered questions from all files"""
        try:
            topics_dir = os.path.join(self.vault_dir, "Topics")
            
            # List of files to search - Biography.md first, then all topic files
            files_to_search = [os.path.join(self.vault_dir, "Biography.md")]
            
            # Add all topic files
            if os.path.exists(topics_dir):
                for filename in os.listdir(topics_dir):
                    if filename.endswith('.md'):
                        files_to_search.append(os.path.join(topics_dir, filename))
            
            questions = []
            
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
                            question = line.strip()[4:].strip()  # Remove "- ❌ "
                            if question and question != "Not asked yet":
                                # Parse custom button labels if they exist
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

                                        questions.append((clean_question, filepath, yes_label, no_label))
                                    else:
                                        questions.append((question, filepath, yes_label, no_label))
                                else:
                                    questions.append((question, filepath, yes_label, no_label))
                                
                                if len(questions) >= limit:
                                    return questions
                                    
                except Exception as e:
                    continue  # Skip files that can't be read

            return questions

        except Exception as e:
            self.log(f"Error searching for questions: {e}")
            return []

    def update_question_status(self, question, status, answer=None):
        """Update the question status using direct Python replacement"""
        try:
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            # Search all markdown files for the question
            search_dirs = [self.vault_dir, os.path.join(self.vault_dir, "Topics")]
            
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
                                pattern = rf'^- ❌ {re.escape(question)}.*?(\[.*?\])?$'
                                if re.search(pattern, content, re.MULTILINE):
                                    # Create replacement text
                                    if status == "yes":
                                        if answer:
                                            new_line = f"- ✅ {question}\n  **Answer:** {answer} *(answered {timestamp})*"
                                        else:
                                            new_line = f"- ✅ {question}\n  **Answer:** Yes *(answered {timestamp})*"
                                    elif status == "no":
                                        new_line = f"- ✅ {question}\n  **Answer:** No *(answered {timestamp})*"
                                    elif status == "skip":
                                        new_line = f"- ⏭ {question} *(skipped {timestamp})*"
                                    else:
                                        new_line = f"- ⏳ {question} *(asked {timestamp})*"
                                    
                                    # Replace the question
                                    updated_content = re.sub(pattern, new_line, content, count=1, flags=re.MULTILINE)
                                    
                                    # Write back to file
                                    with open(filepath, 'w', encoding='utf-8') as f:
                                        f.write(updated_content)
                                    
                                    self.log(f"Updated question status to {status}: {question}")
                                    return
                                    
                            except Exception as e:
                                continue
            
            self.log(f"Question not found in any file: {question}")

        except Exception as e:
            self.log(f"Update failed: {e}")

    def handle_yes(self, notification, action, data):
        """Handle Yes response"""
        self.update_question_status(self.current_question, "yes", self.yes_label)
        self.log(f"User answered '{self.yes_label}' to: {self.current_question}")
        self.questions_answered += 1
        
        if self.loop:
            self.loop.quit()

    def handle_no(self, notification, action, data):
        """Handle No response"""
        self.update_question_status(self.current_question, "no", self.no_label)
        self.log(f"User answered '{self.no_label}' to: {self.current_question}")
        self.questions_answered += 1
        
        if self.loop:
            self.loop.quit()

    def handle_skip(self, notification, action, data):
        """Handle Skip response"""
        self.update_question_status(self.current_question, "skip")
        self.log(f"User SKIPPED question: {self.current_question}")
        
        if self.loop:
            self.loop.quit()

    def send_question(self, question, yes_label, no_label):
        """Send a single question with Yes/No/Skip buttons"""
        self.current_question = question
        self.yes_label = yes_label
        self.no_label = no_label
        
        try:
            notice = Notify.Notification.new(
                f"📖 Biography Question ({self.questions_answered + 1}/10)",
                f"{question}\n",
                "dialog-question"
            )
            notice.set_timeout(0)  # Never expire
            notice.set_urgency(Notify.Urgency.NORMAL)

            # Add action buttons with custom labels
            notice.add_action("yes", f"✅ {yes_label}", self.handle_yes, None)
            notice.add_action("no", f"❌ {no_label}", self.handle_no, None)
            notice.add_action("skip", "⏭ Skip", self.handle_skip, None)

            result = notice.show()
            self.log(f"Question sent: {question}")

            # Keep alive for user interaction (max 5 minutes)
            self.loop = GLib.MainLoop()
            GLib.timeout_add_seconds(300, self.loop.quit)  # 5 minute timeout

            try:
                self.loop.run()
            except KeyboardInterrupt:
                self.log("Question interrupted")

        except Exception as e:
            self.log(f"Error sending question: {e}")

    def run_batch(self, count=10):
        """Run batch of questions"""
        self.log(f"Starting batch of {count} questions")
        
        questions = self.find_unanswered_questions(count)
        
        if not questions:
            self.log("No unanswered questions found")
            print("No unanswered questions found")
            return
        
        self.log(f"Found {len(questions)} unanswered questions")
        print(f"Found {len(questions)} unanswered questions to answer")
        
        for i, (question, filepath, yes_label, no_label) in enumerate(questions):
            print(f"\nQuestion {i+1}/{len(questions)}")
            self.send_question(question, yes_label, no_label)
            
            # Small delay between questions
            time.sleep(1)
        
        self.log(f"Batch complete. Answered {self.questions_answered} questions")
        print(f"\nBatch complete! Answered {self.questions_answered} out of {len(questions)} questions")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Send batch of biography questions')
    parser.add_argument('--count', '-c', type=int, default=10, help='Number of questions to ask (default: 10)')
    args = parser.parse_args()
    
    notifier = BatchQuestionNotifier()
    notifier.run_batch(args.count)