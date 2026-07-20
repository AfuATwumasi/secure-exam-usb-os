#!/bin/bash

set -u

CONFIG_LOADER="/usr/local/lib/exam-kiosk/config-loader.sh"
REPORT_DIR="/var/log/exam-kiosk"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
REPORT_FILE="$REPORT_DIR/diagnostic-$TIMESTAMP.txt"

if [ ! -r "$CONFIG_LOADER" ]; then
    echo "Configuration loader is missing."
    exit 1
fi

source "$CONFIG_LOADER"

if ! load_exam_config; then
    echo "Unable to load configuration."
    exit 1
fi

mkdir -p "$REPORT_DIR"

{
    echo "================================================"
    echo "       KNUST SECURE EXAM OS DIAGNOSTICS"
    echo "================================================"
    echo
    echo "Generated: $(date)"
    echo

    echo "---- Build Information ----"
    echo "Product: $PRODUCT_NAME"
    echo "Institution: $INSTITUTION_NAME"
    echo "Build version: $BUILD_VERSION"
    echo "Schema version: $SCHEMA_VERSION"
    echo

    echo "---- Examination Configuration ----"
    echo "Exam name: $EXAM_NAME"
    echo "Exam URL: $EXAM_URL"
    echo "Exam profile: $EXAM_PROFILE"
    echo "Exam server: $EXAM_SERVER"
    echo

    echo "---- User Configuration ----"
    echo "Exam user: $EXAM_USERNAME"
    echo "Administrator: $ADMIN_USERNAME"
    echo "Autologin enabled: $EXAM_AUTOLOGIN"
    echo

    echo "---- Network Configuration ----"
    echo "Network mode: $NETWORK_MODE"
    echo "Wi-Fi allowed: $ALLOW_WIFI"
    echo "Ethernet allowed: $ALLOW_ETHERNET"
    echo "Internet required: $REQUIRE_INTERNET"
    echo "Trusted network required: $REQUIRE_TRUSTED_NETWORK"
    echo "Trusted SSIDs:"
    get_trusted_ssids | sed 's/^/  - /'
    echo

    echo "---- Current Network Status ----"
    echo "Current SSID:"
    nmcli -t -f active,ssid dev wifi 2>/dev/null |
        awk -F: '$1=="yes"{print substr($0,5)}'
    echo
    echo "Network devices:"
    nmcli device status 2>/dev/null || true
    echo
    echo "IP addresses:"
    ip -brief address 2>/dev/null || true
    echo
    echo "Default route:"
    ip route show default 2>/dev/null || true
    echo

    echo "---- System Information ----"
    echo "Hostname: $(hostname)"
    echo "Architecture: $(uname -m)"
    echo "Kernel: $(uname -r)"
    echo
    echo "Operating system:"
    cat /etc/os-release 2>/dev/null || true
    echo

    echo "---- Memory ----"
    free -h 2>/dev/null || true
    echo

    echo "---- Disk Usage ----"
    df -h 2>/dev/null || true
    echo

    echo "---- Browser Information ----"
    command -v firefox || true
    firefox --version 2>/dev/null || true
    echo

    echo "---- Configuration Validation ----"
    /usr/local/bin/exam-kiosk/validate-config.sh 2>&1 || true
    echo

    echo "---- Recent Exam Engine Log ----"
    tail -n 50 /var/log/exam-kiosk/exam-engine.log 2>/dev/null || true
    echo

    echo "---- Recent Network Log ----"
    tail -n 50 /var/log/exam-kiosk/network.log 2>/dev/null || true
    echo

    echo "================================================"
    echo "End of diagnostic report"
    echo "================================================"

} > "$REPORT_FILE"

chmod 640 "$REPORT_FILE"

echo "Diagnostic report created:"
echo "$REPORT_FILE"
