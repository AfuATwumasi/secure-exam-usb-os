#!/bin/bash

LOG_DIR="${HOME}/.local/share/exam-kiosk"
LOG_FILE="${LOG_DIR}/clipboard-lockdown.log"

mkdir -p "$LOG_DIR"

log_message() {
    printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

# Clear both the normal clipboard and the primary selection.
clear_clipboard() {
    printf '' | xclip -selection clipboard 2>/dev/null || true
    printf '' | xclip -selection primary 2>/dev/null || true
}

# Clear any existing clipboard contents immediately.
clear_clipboard

# Keep clearing clipboard contents during the exam session.
while true; do
    clear_clipboard
    sleep 1
done
