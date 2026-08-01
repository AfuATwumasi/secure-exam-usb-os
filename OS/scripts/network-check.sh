#!/bin/bash

set -u

CONFIG_LOADER="/usr/local/lib/exam-kiosk/config-loader.sh"

if [ ! -r "$CONFIG_LOADER" ]; then
    echo "Configuration loader not found."
    exit 1
fi

source "$CONFIG_LOADER"

load_exam_config || exit 1

LOG_DIR="$HOME/.local/share/exam-kiosk"
LOG_FILE="$LOG_DIR/network.log"

mkdir -p "$LOG_DIR"

log() {
    printf '%s - %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$1" >> "$LOG_FILE"
}

get_current_ssid() {
    nmcli -t -f active,ssid dev wifi 2>/dev/null |
        awk -F: '$1=="yes"{print substr($0,5);exit}'
}

WAITED=0

log "Starting network verification."

while [ "$WAITED" -lt "$NETWORK_TIMEOUT" ]
do

    CURRENT_SSID=$(get_current_ssid)

    if [ "$REQUIRE_TRUSTED_NETWORK" = "true" ]; then

        if [ -z "$CURRENT_SSID" ]; then
            sleep 2
            WAITED=$((WAITED+2))
            continue
        fi

        if ! is_trusted_ssid "$CURRENT_SSID"; then
            log "Unauthorized SSID: $CURRENT_SSID"

            sleep 2
            WAITED=$((WAITED+2))
            continue
        fi

        log "Trusted SSID verified."
    fi

    if [ "$REQUIRE_INTERNET" = "true" ]; then

        if ! ping -c1 -W3 "$INTERNET_TEST_HOST" >/dev/null 2>&1
        then
            log "Internet unavailable."

            sleep 2
            WAITED=$((WAITED+2))
            continue
        fi

        log "Internet verified."
    fi

    if [ "$REQUIRE_EXAM_SERVER" = "true" ]; then

        if ! curl -fs --connect-timeout 5 "$EXAM_URL" >/dev/null 2>&1
        then
            log "Exam server unreachable."

            sleep 2
            WAITED=$((WAITED+2))
            continue
        fi

        log "Exam server verified."
    fi

    log "Network verification successful."

    exit 0

done

log "Network verification failed."

exit 1
