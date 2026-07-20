#!/bin/bash

set -u

CONFIG_LOADER="/usr/local/lib/exam-kiosk/config-loader.sh"

source "$CONFIG_LOADER"

load_exam_config || exit 1

LOG_DIR="$HOME/.local/share/exam-kiosk"
LOG_FILE="$LOG_DIR/browser.log"

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

    firefox \
        --kiosk \
        "$EXAM_URL"

    if [ "$RESTART_BROWSER" != "true" ]
    then
        break
    fi

    log "Firefox closed. Restarting."

    sleep 1

done
