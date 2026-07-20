#!/bin/bash

set -u

BIN_DIR="/usr/local/bin/exam-kiosk"
LOG_DIR="${HOME}/.local/share/exam-kiosk"
LOG_FILE="$LOG_DIR/exam-engine.log"

mkdir -p "$LOG_DIR"

log() {
    printf '%s - %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$1" >> "$LOG_FILE"
}

run_step() {
    local description="$1"
    local command="$2"

    log "$description"

    if ! "$command"; then
        log "FAILED: $description"

        zenity \
            --error \
            --title="KNUST Exam OS" \
            --width=450 \
            --text="The examination environment could not complete this step:\n\n${description}"

        exit 1
    fi

    log "COMPLETED: $description"
}

log "Starting KNUST Exam Engine."

run_step \
    "Validating examination configuration." \
    "$BIN_DIR/validate-config.sh"

run_step \
    "Applying examination desktop restrictions." \
    "$BIN_DIR/lockdown.sh"

run_step \
    "Connecting to and verifying the examination network." \
    "$BIN_DIR/network-assistant.sh"

log "Launching the examination browser."

run_step \
    "Applying operating system hardening." \
    "$BIN_DIR/system-hardening.sh"
exec "$BIN_DIR/start-exam.sh"
