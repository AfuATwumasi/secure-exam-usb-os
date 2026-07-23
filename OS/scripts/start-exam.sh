#!/bin/bash

set -u

CONFIG_LOADER="/usr/local/lib/exam-kiosk/config-loader.sh"

source "$CONFIG_LOADER"

load_exam_config || exit 1

LOG_DIR="$HOME/.local/share/exam-kiosk"
LOG_FILE="$LOG_DIR/browser.log"
UNLOCK_FLAG="/run/exam-kiosk/admin-unlocked"
mkdir -p "$LOG_DIR"

log() {

    printf '%s - %s\n' \
        "$(date '+%F %T')" \
        "$1" >> "$LOG_FILE"

}

log "Starting browser."

sleep "$STARTUP_DELAY"

while true
do
    if [ -e "$UNLOCK_FLAG" ]; then
        log "Administrator unlock detected. Browser will not start."
        break
    fi

    firefox \
        --kiosk \
        "$EXAM_URL"

    if [ -e "$UNLOCK_FLAG" ]; then
        log "Administrator unlock detected. Browser restart disabled."
        break
    fi

    if [ "$RESTART_BROWSER" != "true" ]; then
        break
    fi

    log "Firefox closed. Restarting."

    sleep 1
done
