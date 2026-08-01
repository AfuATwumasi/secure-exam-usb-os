#!/bin/bash

set -u

LOG_DIR="${HOME}/.local/share/exam-kiosk"
LOG_FILE="${LOG_DIR}/restore-desktop.log"

mkdir -p "$LOG_DIR"

log() {
    printf '%s - %s\n' "$(date '+%F %T')" "$1" >> "$LOG_FILE"
}

set_value() {
    local channel="$1"
    local property="$2"
    local type="$3"
    local value="$4"

    xfconf-query \
        --channel "$channel" \
        --property "$property" \
        --create \
        --type "$type" \
        --set "$value" 2>>"$LOG_FILE" || true
}

set_shortcut() {
    local property="$1"
    local command="$2"

    xfconf-query \
        --channel xfce4-keyboard-shortcuts \
        --property "$property" \
        --create \
        --type string \
        --set "$command" 2>>"$LOG_FILE" || true
}

log "Restoring administrator desktop access."

# Restore desktop icons and menus.
set_value "xfce4-desktop" "/desktop-icons/style" "int" "2"
set_value "xfce4-desktop" "/desktop-menu/show" "bool" "true"
set_value "xfce4-desktop" "/windowlist-menu/show" "bool" "true"

# Restore panels.
set_value "xfce4-panel" "/panels/panel-1/autohide-behavior" "uint" "0"
set_value "xfce4-panel" "/panels/panel-1/length" "uint" "100"
set_value "xfce4-panel" "/panels/panel-2/autohide-behavior" "uint" "0"
set_value "xfce4-panel" "/panels/panel-2/length" "uint" "100"

# Restore common XFCE shortcuts.
set_shortcut "/commands/custom/<Primary><Alt>t" "exo-open --launch TerminalEmulator"
set_shortcut "/commands/custom/<Alt>F2" "xfce4-appfinder --collapsed"
set_shortcut "/commands/custom/<Alt>F1" "xfce4-popup-applicationsmenu"
set_shortcut "/commands/custom/Super_L" "xfce4-popup-whiskermenu"

set_shortcut "/xfwm4/custom/<Alt>Tab" "cycle_windows_key"
set_shortcut "/xfwm4/custom/<Shift><Alt>Tab" "cycle_reverse_windows_key"

# Stop clipboard clearing.
pkill -f '/usr/local/bin/exam-kiosk/clipboard-lockdown.sh' \
    >/dev/null 2>&1 || true

# Restore normal display power handling.
xset s on 2>>"$LOG_FILE" || true
xset +dpms 2>>"$LOG_FILE" || true

xfce4-panel -r >/dev/null 2>&1 || true

log "Administrator desktop access restored."

exit 0
