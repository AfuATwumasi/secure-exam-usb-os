#!/bin/bash

# Shared configuration loader for KNUST Secure Exam OS.

EXAM_CONFIG_DIR="${EXAM_CONFIG_DIR:-/etc/exam-kiosk}"
SYSTEM_CONFIG_FILE="${SYSTEM_CONFIG_FILE:-$EXAM_CONFIG_DIR/system.json}"
VERSION_FILE="$EXAM_CONFIG_DIR/version"

config_error() {
    printf 'Configuration error: %s\n' "$1" >&2
    return 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        config_error "Required command is unavailable: $1"
        return 1
    }
}

require_file() {
    [ -f "$1" ] || {
        config_error "Required file is missing: $1"
        return 1
    }
}

validate_system_config() {
    require_command jq || return 1
    require_file "$SYSTEM_CONFIG_FILE" || return 1

    jq empty "$SYSTEM_CONFIG_FILE" >/dev/null 2>&1 || {
        config_error "Invalid JSON file: $SYSTEM_CONFIG_FILE"
        return 1
    }

    local schema_version

    schema_version=$(
        jq -r '.schema_version // empty' \
            "$SYSTEM_CONFIG_FILE" 2>/dev/null
    )

    if [ -z "$schema_version" ]; then
        config_error "The configuration has no schema_version."
        return 1
    fi

    return 0
}

json_value() {
    local filter="$1"
    local default_value="${2:-}"
    local result

    result=$(
        jq -r "$filter // empty" \
            "$SYSTEM_CONFIG_FILE" 2>/dev/null
    )

    if [ -n "$result" ] && [ "$result" != "null" ]; then
        printf '%s\n' "$result"
    else
        printf '%s\n' "$default_value"
    fi
}

load_exam_config() {
    validate_system_config || return 1

    SCHEMA_VERSION=$(json_value '.schema_version' '1.0')

    # Examination
    EXAM_NAME=$(json_value '.exam.name' 'KNUST Examination')
    EXAM_URL=$(json_value '.exam.url' '')
    EXAM_PROFILE=$(json_value '.exam.profile' 'standard')

    # Browser
    KIOSK_MODE=$(json_value '.browser.kiosk_mode' 'true')
    RESTART_BROWSER=$(json_value '.browser.restart_browser' 'true')
    STARTUP_DELAY=$(json_value '.browser.startup_delay' '5')

    # System
    SYSTEM_HOSTNAME=$(json_value '.system.hostname' 'knust-exam')
    BUILD_VERSION=$(json_value '.system.build_version' '1.0.0')

    # Network
    NETWORK_MODE=$(json_value '.network.mode' 'trusted-network')

    ALLOW_WIFI=$(
        json_value '.network.connection.allow_wifi' 'true'
    )

    ALLOW_ETHERNET=$(
        json_value '.network.connection.allow_ethernet' 'false'
    )

    REQUIRE_TRUSTED_NETWORK=$(
        json_value \
            '.network.verification.require_trusted_network' \
            'true'
    )

    REQUIRE_INTERNET=$(
        json_value \
            '.network.verification.require_internet' \
            'true'
    )

    REQUIRE_EXAM_SERVER=$(
        json_value \
            '.network.verification.require_exam_server' \
            'true'
    )

    INTERNET_TEST_HOST=$(
        json_value \
            '.network.verification.internet_test_host' \
            '1.1.1.1'
    )

    EXAM_SERVER=$(
        json_value \
            '.network.verification.exam_server' \
            ''
    )

    NETWORK_TIMEOUT=$(
        json_value \
            '.network.verification.timeout_seconds' \
            '20'
    )

    # Security
    DISABLE_TERMINAL=$(
        json_value \
            '.security.desktop.disable_terminal' \
            'true'
    )

    DISABLE_ALT_TAB=$(
        json_value \
            '.security.keyboard.disable_alt_tab' \
            'true'
    )

    DISABLE_SUPER_KEY=$(
        json_value \
            '.security.keyboard.disable_super_key' \
            'true'
    )

    DISABLE_WORKSPACE_SWITCHING=$(
        json_value \
            '.security.keyboard.disable_workspace_switching' \
            'true'
    )

    DISABLE_RIGHT_CLICK=$(
        json_value \
            '.security.desktop.disable_right_click' \
            'true'
    )

    DISABLE_DESKTOP_ICONS=$(
        json_value \
            '.security.desktop.disable_desktop_icons' \
            'true'
    )

    DISABLE_SCREEN_LOCK=$(
        json_value \
            '.security.session.disable_screen_lock' \
            'true'
    )

    DISABLE_USB_STORAGE=$(
        json_value \
            '.security.devices.disable_usb_storage' \
            'false'
    )

    # Branding
    PRODUCT_NAME=$(
        json_value \
            '.branding.product_name' \
            'KNUST Secure Exam OS'
    )

    INSTITUTION_NAME=$(
        json_value \
            '.branding.institution' \
            'Kwame Nkrumah University of Science and Technology'
    )

    WALLPAPER_PATH=$(
        json_value '.branding.wallpaper' ''
    )

    SHOW_BUILD_VERSION=$(
        json_value '.branding.show_build_version' 'true'
    )

    # User accounts
    ADMIN_USERNAME=$(
        json_value '.administrator.username' 'admin'
    )

    ADMIN_GUI_LOGIN=$(
        json_value '.administrator.allow_gui_login' 'true'
    )

    ADMIN_RECOVERY=$(
        json_value '.administrator.allow_recovery' 'true'
    )

    EXAM_USERNAME=$(
        json_value '.student.username' 'exam'
    )

    EXAM_AUTOLOGIN=$(
        json_value '.student.autologin' 'true'
    )

    export SCHEMA_VERSION

    export EXAM_NAME
    export EXAM_URL
    export EXAM_PROFILE

    export KIOSK_MODE
    export RESTART_BROWSER
    export STARTUP_DELAY

    export SYSTEM_HOSTNAME
    export BUILD_VERSION

    export NETWORK_MODE
    export ALLOW_WIFI
    export ALLOW_ETHERNET
    export REQUIRE_TRUSTED_NETWORK
    export REQUIRE_INTERNET
    export REQUIRE_EXAM_SERVER
    export INTERNET_TEST_HOST
    export EXAM_SERVER
    export NETWORK_TIMEOUT

    export DISABLE_TERMINAL
    export DISABLE_ALT_TAB
    export DISABLE_SUPER_KEY
    export DISABLE_WORKSPACE_SWITCHING
    export DISABLE_RIGHT_CLICK
    export DISABLE_DESKTOP_ICONS
    export DISABLE_SCREEN_LOCK
    export DISABLE_USB_STORAGE

    export PRODUCT_NAME
    export INSTITUTION_NAME
    export WALLPAPER_PATH
    export SHOW_BUILD_VERSION

    export ADMIN_USERNAME
    export ADMIN_GUI_LOGIN
    export ADMIN_RECOVERY
    export EXAM_USERNAME
    export EXAM_AUTOLOGIN

    return 0
}

get_trusted_ssids() {
    jq -r \
        '.network.trusted_networks[]?.ssid' \
        "$SYSTEM_CONFIG_FILE" 2>/dev/null
}

is_trusted_ssid() {
    local ssid="$1"

    jq -e \
        --arg ssid "$ssid" \
        '.network.trusted_networks[]? |
         select(.ssid == $ssid)' \
        "$SYSTEM_CONFIG_FILE" >/dev/null 2>&1
}
