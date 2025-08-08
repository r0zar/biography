#!/usr/bin/env python3

import os
import re
from datetime import datetime, timezone
import time

# Auto-load configuration
from auto_config import VAULT_DIR, TOPICS_DIR, BIOGRAPHY_FILE


def get_pronoun_info():
    """Extract pronoun preference from biography"""
    try:
        biography_path = BIOGRAPHY_FILE
        with open(biography_path, 'r', encoding='utf-8') as f:
            content = f.read()

        if "**Answer:** He/Him" in content:
            return "he", "his", "him"
        elif "**Answer:** She/Her" in content:
            return "she", "her", "her"
        else:
            return "they", "their", "them"
    except Exception:
        return "they", "their", "them"


def get_todays_answers():
    """Extract today's answered questions and responses from all files"""
    # Use local timezone for proper date handling
    local_now = datetime.now()
    date_today = local_now.strftime("%Y-%m-%d")
    answers = []

    # Search only topic files - Biography.md no longer contains questions
    search_dirs = [TOPICS_DIR]

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
                    pattern = rf'- ✅ ([^\n]+\?)\s*\n\s*\*\*Answer:\*\* ([^*]+) \*\(answered {date_today}[^)]*\)\*'
                    matches = re.findall(pattern, content, re.MULTILINE)

                    for question, answer in matches:
                        # Clean up the text
                        question = re.sub(r'\\n.*', '', question).strip()
                        answer = answer.strip()

                        if question and answer and len(question) > 20:
                            answers.append((question, answer))

                except Exception:
                    continue

    return answers


def get_answers_from_date(target_date):
    """Extract answered questions and responses from a specific date"""
    answers = []

    # Search only topic files - Biography.md no longer contains questions
    search_dirs = [TOPICS_DIR]

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

                    # Look for answered questions with target date
                    pattern = rf'- ✅ ([^\n]+\?)\s*\n\s*\*\*Answer:\*\* ([^*]+) \*\(answered {target_date}[^)]*\)\*'
                    matches = re.findall(pattern, content, re.MULTILINE)

                    for question, answer in matches:
                        # Clean up the text
                        question = re.sub(r'\\n.*', '', question).strip()
                        answer = answer.strip()

                        if question and answer and len(question) > 20:
                            answers.append((question, answer))

                except Exception:
                    continue

    return answers


if __name__ == "__main__":
    import sys
    from datetime import timedelta

    # Default to today, but allow specifying a different date
    if len(sys.argv) > 2 and sys.argv[1] != "count" and sys.argv[1] != "pronouns":
        # Format: script.py date YYYY-MM-DD
        target_date = sys.argv[2]
        qa_pairs = get_answers_from_date(target_date)
    else:
        # For backwards compatibility, try today first, then yesterday
        qa_pairs = get_todays_answers()
        if not qa_pairs:
            # Try yesterday
            yesterday = (datetime.now() - timedelta(days=1)
                         ).strftime("%Y-%m-%d")
            qa_pairs = get_answers_from_date(yesterday)

    pronoun, possessive, objective = get_pronoun_info()

    if len(sys.argv) > 1 and sys.argv[1] == "count":
        print(len(qa_pairs))
    elif len(sys.argv) > 1 and sys.argv[1] == "pronouns":
        print(f"{pronoun}|{possessive}|{objective}")
    else:
        # Output Q&A data for Claude
        date_today = datetime.now().strftime("%Y-%m-%d")
        print(f"Q&A data from recent sessions ({len(qa_pairs)} questions):")
        print()

        for question, answer in qa_pairs:
            print(f"Q: {question}")
            print(f"A: {answer}")
            print()
