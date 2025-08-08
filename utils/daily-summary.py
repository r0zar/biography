#!/usr/bin/env python3

import os
import re
import sys
import subprocess
from datetime import datetime

# Auto-load configuration
from auto_config import VAULT_DIR, LOGS_DIR, SCRIPTS_DIR

LOG_FILE = os.path.join(LOGS_DIR, 'daily-summary.log')


def log(message):
    """Log messages with timestamp"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, "a") as f:
        f.write(f"{timestamp}: {message}\n")


def get_todays_answers():
    """Extract today's answered questions and responses from all files"""
    date_today = datetime.now().strftime("%Y-%m-%d")
    answers = []

    # Search Biography.md and all topic files
    search_dirs = [VAULT_DIR, os.path.join(VAULT_DIR, "Topics")]

    for search_dir in search_dirs:
        if not os.path.exists(search_dir):
            continue

        for root, dirs, files in os.walk(search_dir):
            for file in files:
                if not file.endswith('.md'):
                    continue

                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Look for answered questions with today's date
                    pattern = rf'- ✅ (.*?)\n\s*\*\*Answer:\*\* (.*?) \*\(answered {date_today}.*?\)\*'
                    matches = re.findall(
                        pattern, content, re.MULTILINE | re.DOTALL)

                    for question, answer in matches:
                        # Clean up the text
                        question = re.sub(r'\\n.*', '', question).strip()
                        answer = answer.strip()

                        if question and answer and len(question) > 10:
                            answers.append((question, answer))

                except Exception as e:
                    log(f"Error reading {filepath}: {e}")
                    continue

    log(f"Found {len(answers)} answered questions from today")
    return answers


def get_pronoun_info():
    """Extract pronoun preference from biography"""
    try:
        biography_path = os.path.join(VAULT_DIR, "Biography.md")
        with open(biography_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check if pronoun question is answered
        if "**Answer:** He/Him" in content:
            return "he", "his", "him"
        elif "**Answer:** She/Her" in content:
            return "she", "her", "her"
        else:
            return "they", "their", "them"
    except Exception as e:
        log(f"Error getting pronouns: {e}")
        return "they", "their", "them"


def generate_narrative(qa_pairs):
    """Generate personal narrative using Claude via shell execution"""
    if not qa_pairs:
        return "No questions were answered today."

    # Get pronoun information
    pronoun, possessive, objective = get_pronoun_info()

    # Format Q&A for Claude - limit to avoid overwhelming
    qa_text = ""
    for question, answer in qa_pairs:
        qa_text += f"Q: {question}\nA: {answer}\n\n"

    date_today = datetime.now().strftime("%Y-%m-%d")
    prompt = f"""Based on these Q&A responses from today ({date_today}), write a 200-300 word personal narrative about this person. Write in third person using {pronoun}/{possessive}/{objective} pronouns, focusing on who they are as a person, their current situation, challenges, values, and what makes them unique.

{qa_text}

Write a flowing narrative that captures their essence based on today's responses. Use {pronoun}/{possessive}/{objective} pronouns consistently."""

    log(f"Prompt length: {len(prompt)} characters")

    # Write prompt to temp file
    import tempfile
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write(prompt)
            prompt_file = f.name

        # Use shell execution instead of subprocess to avoid stdout capture issues
        import os
        output_file = f"/tmp/claude_output_{os.getpid()}.txt"

        # Execute claude wrapper and redirect output to file
        cmd = f"{SCRIPTS_DIR}/utils/claude-wrapper.sh \"$(cat {prompt_file})\" > {output_file} 2>&1"
        result_code = os.system(cmd)

        log(f"Claude shell command return code: {result_code}")

        # Read the output file
        narrative = ""
        if os.path.exists(output_file):
            with open(output_file, 'r', encoding='utf-8') as f:
                narrative = f.read().strip()
            os.unlink(output_file)  # Clean up

        os.unlink(prompt_file)  # Clean up

        if narrative and len(narrative) > 10:
            log(
                f"Successfully generated narrative: {len(narrative)} characters")
            return narrative
        else:
            log(f"Claude returned minimal output: '{narrative}'")

    except Exception as e:
        log(f"Error calling Claude: {e}")

    # Fallback to basic summary if Claude fails
    log("Using fallback narrative generation")
    return f"Today {pronoun} answered {len(qa_pairs)} questions across various topics, demonstrating ongoing self-reflection during {possessive} current life transition and career development journey."


def create_daily_summary():
    """Create or update the daily summary file"""
    date_today = datetime.now().strftime("%Y-%m-%d")
    daily_file = os.path.join(VAULT_DIR, f"{date_today}.md")

    log(f"Creating daily summary for {date_today}")

    # Get today's Q&A data
    qa_pairs = get_todays_answers()
    narrative = generate_narrative(qa_pairs)

    # Create the daily summary content
    content = f"""# Daily Portrait - {datetime.now().strftime('%B %d, %Y')}

*A personal narrative based on today's biography questions*

---

{narrative}

---

**Questions explored today:** {len(qa_pairs)}  
*Generated on {datetime.now().strftime('%Y-%m-%d at %I:%M %p')}*

## Today's Q&A Summary

---

[[Biography]] | [[{(datetime.now().replace(day=datetime.now().day-1)).strftime('%Y-%m-%d')}]] | [[{(datetime.now().replace(day=datetime.now().day+1)).strftime('%Y-%m-%d')}]]

#daily #portrait #biography #{datetime.now().strftime('%Y')} #{datetime.now().strftime('%B').lower()}
"""

    # Write the file
    try:
        with open(daily_file, 'w', encoding='utf-8') as f:
            f.write(content)
        log(f"Daily summary created: {daily_file}")
        print(daily_file)
        return daily_file
    except Exception as e:
        log(f"Error writing daily file: {e}")
        return None


if __name__ == "__main__":
    # Ensure log directory exists
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

    if len(sys.argv) > 1 and sys.argv[1] == "create":
        create_daily_summary()
    else:
        print("Usage: daily-summary.py create")
