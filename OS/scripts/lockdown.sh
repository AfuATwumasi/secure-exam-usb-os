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

if [ "$(read_setting '.desktop.hide_panel')" = "true" ]; then
    # Hide both XFCE panels
    set_xfconf "xfce4-panel" "/panels/panel-1/autohide-behavior" "uint" "2"
    set_xfconf "xfce4-panel" "/panels/panel-2/autohide-behavior" "uint" "2"

    set_xfconf "xfce4-panel" "/panels/panel-1/length" "uint" "0"
    set_xfconf "xfce4-panel" "/panels/panel-2/length" "uint" "0"

    xfce4-panel -r >/dev/null 2>&1 || true

    log_message "XFCE panels hidden."
fi
# --------------------------------------------------
# Keyboard shortcut restrictions
# --------------------------------------------------

if [ "$(read_setting '.keyboard.disable_ctrl_alt_t')" = "true" ]; then
    for property in \
        "/commands/custom/<Primary><Alt>t" \
        "/commands/custom/<Control><Alt>t"
    do
        set_xfconf \
            "xfce4-keyboard-shortcuts" \
            "$property" \
            "string" \
            "/bin/true"
    done

    log_message "Terminal keyboard shortcuts neutralized."
fi

if [ "$(read_setting '.keyboard.disable_run_dialog')" = "true" ]; then
    set_xfconf \
        "xfce4-keyboard-shortcuts" \
        "/commands/custom/<Alt>F2" \
        "string" \
        "/bin/true"

    log_message "Run-dialog shortcut neutralized."
fi

if [ "$(read_setting '.keyboard.disable_super_key')" = "true" ]; then
    # Remove common XFCE application-menu and Super-key bindings.
for property in \
    "/commands/custom/Super_L" \
    "/commands/custom/Super_R" \
    "/commands/custom/<Super>r" \
    "/commands/custom/<Super>e" \
    "/commands/custom/<Super>d" \
    "/commands/custom/<Alt>F1"
do
    set_xfconf \
        "xfce4-keyboard-shortcuts" \
        "$property" \
        "string" \
        "/bin/true"
done

    # Prevent the Whisker menu from opening from the Super key.
    set_xfconf \
        "xfce4-keyboard-shortcuts" \
        "/commands/custom/Super_L" \
        "string" \
        "/bin/true"

    set_xfconf \
        "xfce4-keyboard-shortcuts" \
        "/commands/custom/Super_R" \
        "string" \
        "/bin/true"

    log_message " Super-key shortcuts neutralized."
fi

if [ "$(read_setting '.keyboard.disable_alt_tab')" = "true" ]; then
    for property in \
        "/xfwm4/custom/<Alt>Tab" \
        "/xfwm4/custom/<Shift><Alt>Tab" \
        "/xfwm4/custom/<Alt>Escape" \
        "/xfwm4/custom/<Shift><Alt>Escape"
    do
        set_xfconf \
            "xfce4-keyboard-shortcuts" \
            "$property" \
            "string" \
            "/bin/true"
    done

    log_message "Window-switching shortcuts neutralized."
fi

if [ "$(read_setting '.keyboard.disable_alt_f4')" = "true" ]; then
    set_xfconf \
        "xfce4-keyboard-shortcuts" \
        "/xfwm4/custom/<Alt>F4" \
        "string" \
        "/bin/true"

    log_message "Alt+F4 shortcut neutralized."
fi

if [ "$(read_setting '.keyboard.disable_print_screen')" = "true" ]; then
    for property in \
        "/commands/custom/Print" \
        "/commands/custom/<Alt>Print" \
        "/commands/custom/<Shift>Print" \
        "/commands/custom/<Primary>Print"
    do
        set_xfconf \
            "xfce4-keyboard-shortcuts" \
            "$property" \
            "string" \
            "/bin/true"
    done

    log_message "Screenshot shortcuts neutralized."
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

# Administrator unlock shortcut.
set_xfconf \
    "xfce4-keyboard-shortcuts" \
    "/commands/custom/<Primary><Alt><Shift>u" \
    "string" \
    "/usr/local/bin/exam-kiosk/admin-unlock.sh"

log_message "Administrator unlock shortcut configured."

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

if [ "$(read_setting '.browser.disable_clipboard')" = "true" ]; then
    pkill -f '/usr/local/bin/exam-kiosk/clipboard-lockdown.sh' \
        >/dev/null 2>&1 || true

    nohup /usr/local/bin/exam-kiosk/clipboard-lockdown.sh \
        >/dev/null 2>&1 &

    log_message "Clipboard clearing service started."
fi
# Start the examination keyboard guard.
XBINDKEYS_CONFIG="/etc/exam-kiosk/xbindkeysrc"

if command -v xbindkeys >/dev/null 2>&1 && [ -f "$XBINDKEYS_CONFIG" ]; then
    pkill -x xbindkeys >/dev/null 2>&1 || true

    nohup xbindkeys --file "$XBINDKEYS_CONFIG" \
        >>"$LOG_FILE" 2>&1 &

    sleep 1

    if pgrep -x xbindkeys >/dev/null 2>&1; then
        log_message "Keyboard guard started."
    else
        log_message "WARNING: Keyboard guard failed to start."
    fi
else
    log_message "WARNING: xbindkeys or its configuration is missing."
fi

log_message "XFCE lockdown completed."

exit 0
