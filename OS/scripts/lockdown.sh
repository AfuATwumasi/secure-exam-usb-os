#!/bin/bash

SECURITY_CONFIG="/etc/exam-kiosk/security.json"
LOG_DIR="${HOME}/.local/share/exam-kiosk"
LOG_FILE="${LOG_DIR}/lockdown.log"

mkdir -p "$LOG_DIR"

log_message() {
    printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

read_setting() {
    jq -r "$1 // false" "$SECURITY_CONFIG" 2>/dev/null
}

set_xfconf() {
    local channel="$1"
    local property="$2"
    local type="$3"
    local value="$4"

    xfconf-query \
        --channel "$channel" \
        --property "$property" \
        --create \
        --type "$type" \
        --set "$value" 2>>"$LOG_FILE"
}

remove_xfconf_property() {
    local channel="$1"
    local property="$2"

    xfconf-query \
        --channel "$channel" \
        --property "$property" \
        --reset \
        2>>"$LOG_FILE" || true
}

if [ ! -f "$SECURITY_CONFIG" ]; then
    log_message "ERROR: Security configuration was not found."
    exit 1
fi

if ! jq empty "$SECURITY_CONFIG" >/dev/null 2>&1; then
    log_message "ERROR: security.json contains invalid JSON."
    exit 1
fi

log_message "Beginning XFCE lockdown."

# Wait until the XFCE settings service is available.
for attempt in $(seq 1 20); do
    if xfconf-query --channel xfce4-desktop --list >/dev/null 2>&1; then
        break
    fi

    sleep 1
done

# --------------------------------------------------
# Desktop restrictions
# --------------------------------------------------

if [ "$(read_setting '.desktop.disable_desktop_icons')" = "true" ]; then
    # 0 = no desktop icons
    set_xfconf "xfce4-desktop" "/desktop-icons/style" "int" "0"
    log_message "Desktop icons disabled."
fi

if [ "$(read_setting '.desktop.disable_right_click')" = "true" ]; then
    set_xfconf "xfce4-desktop" "/desktop-menu/show" "bool" "false"
    set_xfconf "xfce4-desktop" "/windowlist-menu/show" "bool" "false"
    log_message "Desktop right-click menus disabled."
fi

# --------------------------------------------------
# Keyboard shortcut restrictions
# --------------------------------------------------

if [ "$(read_setting '.keyboard.disable_ctrl_alt_t')" = "true" ]; then
    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/commands/custom/<Primary><Alt>t"

    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/commands/custom/<Control><Alt>t"

    log_message "Terminal keyboard shortcut disabled."
fi

if [ "$(read_setting '.keyboard.disable_run_dialog')" = "true" ]; then
    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/commands/custom/<Alt>F2"

    log_message "Run-dialog shortcut disabled."
fi

if [ "$(read_setting '.keyboard.disable_super_key')" = "true" ]; then
    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/commands/custom/Super_L"

    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/commands/custom/<Super>r"

    log_message "Configured Super-key shortcuts removed."
fi

if [ "$(read_setting '.keyboard.disable_alt_tab')" = "true" ]; then
    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/xfwm4/custom/<Alt>Tab"

    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/xfwm4/custom/<Shift><Alt>Tab"

    log_message "Alt+Tab window-switching shortcuts removed."
fi

if [ "$(read_setting '.keyboard.disable_workspace_switching')" = "true" ]; then
    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/xfwm4/custom/<Primary><Alt>Left"

    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/xfwm4/custom/<Primary><Alt>Right"

    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/xfwm4/custom/<Primary><Alt>Up"

    remove_xfconf_property \
        "xfce4-keyboard-shortcuts" \
        "/xfwm4/custom/<Primary><Alt>Down"

    log_message "Workspace-switching shortcuts removed."
fi

# --------------------------------------------------
# Session restrictions
# --------------------------------------------------

if [ "$(read_setting '.session.disable_screen_lock')" = "true" ]; then
    set_xfconf "xfce4-session" \
        "/shutdown/LockScreen" \
        "bool" \
        "false"

    set_xfconf "xfce4-power-manager" \
        "/xfce4-power-manager/lock-screen-suspend-hibernate" \
        "bool" \
        "false"

    log_message "Automatic screen locking disabled."
fi

if [ "$(read_setting '.session.disable_suspend')" = "true" ]; then
    set_xfconf "xfce4-power-manager" \
        "/xfce4-power-manager/inactivity-on-ac" \
        "uint" \
        "0"

    set_xfconf "xfce4-power-manager" \
        "/xfce4-power-manager/inactivity-on-battery" \
        "uint" \
        "0"

    log_message "Desktop inactivity suspend disabled."
fi

# Disable screen blanking during the examination.
xset s off 2>>"$LOG_FILE" || true
xset s noblank 2>>"$LOG_FILE" || true
xset -dpms 2>>"$LOG_FILE" || true

log_message "XFCE lockdown completed."

exit 0
