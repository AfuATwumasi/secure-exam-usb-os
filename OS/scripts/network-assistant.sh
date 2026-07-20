#!/bin/bash

set -u

CONFIG="/etc/exam-kiosk/network.json"
NETWORK_CHECK="/usr/local/bin/exam-kiosk/network-check.sh"
LOG_DIR="${HOME}/.local/share/exam-kiosk"
LOG_FILE="$LOG_DIR/network-assistant.log"

mkdir -p "$LOG_DIR"

log() {
    printf '%s - %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$1" >> "$LOG_FILE"
}

get_trusted_ssids() {
    jq -r '.trusted_networks[]?.ssid' "$CONFIG" 2>/dev/null
}

show_network_instructions() {
    local trusted_networks

    trusted_networks=$(get_trusted_ssids | sed 's/^/• /')

    zenity \
        --info \
        --title="KNUST Exam Network" \
        --width=470 \
        --text="Connect this computer to an authorized examination network.\n\nApproved network:\n${trusted_networks}\n\nAfter connecting, click Continue." \
        --ok-label="Continue"
}

show_failure_message() {
    zenity \
        --question \
        --title="Network Not Ready" \
        --width=470 \
        --text="The authorized examination network or examination server could not be verified.\n\nWould you like to open the Wi-Fi connection window?" \
        --ok-label="Open Wi-Fi Settings" \
        --cancel-label="Retry"
}

if [ ! -f "$CONFIG" ]; then
    zenity \
        --error \
        --title="Configuration Error" \
        --text="The examination network configuration is missing."

    exit 1
fi

if ! jq empty "$CONFIG" >/dev/null 2>&1; then
    zenity \
        --error \
        --title="Configuration Error" \
        --text="The examination network configuration is invalid."

    exit 1
fi

log "Starting network assistant."

show_network_instructions

while true; do
    log "Checking examination network."

    if "$NETWORK_CHECK"; then
        log "Authorized examination network verified."

        zenity \
            --info \
            --timeout=3 \
            --title="Network Ready" \
            --text="The examination network has been verified."

        exit 0
    fi

    log "Network verification failed."

    if show_failure_message; then
        log "Opening Network Manager connection editor."

        nm-connection-editor >/dev/null 2>&1 &
        wait $!

        sleep 2
    else
        log "User selected network verification retry."
    fi
done
