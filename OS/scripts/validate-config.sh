#!/bin/bash

set -u

CONFIG_LOADER="/usr/local/lib/exam-kiosk/config-loader.sh"

if [ ! -r "$CONFIG_LOADER" ]; then
    echo "Configuration loader is missing." >&2
    exit 1
fi

source "$CONFIG_LOADER"

if ! validate_system_config; then
    echo "Master configuration validation failed." >&2
    exit 1
fi

load_exam_config || exit 1

ERRORS=0

report_error() {
    echo "ERROR: $1" >&2
    ERRORS=$((ERRORS + 1))
}

[ -n "$EXAM_NAME" ] ||
    report_error "Exam name is empty."

[ -n "$EXAM_URL" ] ||
    report_error "Exam URL is empty."

case "$EXAM_URL" in
    http://*|https://*)
        ;;
    *)
        report_error "Exam URL must begin with http:// or https://."
        ;;
esac

if [ "$REQUIRE_EXAM_SERVER" = "true" ] &&
   [ -z "$EXAM_SERVER" ]; then
    report_error \
        "Exam server is required but no server is configured."
fi

if [ "$REQUIRE_TRUSTED_NETWORK" = "true" ] &&
   [ -z "$(get_trusted_ssids)" ]; then
    report_error \
        "A trusted network is required but no SSID is configured."
fi

case "$NETWORK_TIMEOUT" in
    ''|*[!0-9]*)
        report_error \
            "Network timeout must be a positive integer."
        ;;
    *)
        if [ "$NETWORK_TIMEOUT" -lt 1 ]; then
            report_error \
                "Network timeout must be greater than zero."
        fi
        ;;
esac

if [ "$ERRORS" -gt 0 ]; then
    echo "Configuration validation found $ERRORS error(s)." >&2
    exit 1
fi

echo "Master configuration is valid."
exit 0
