#!/bin/bash

set -eu

EXAM_USER="exam"
EXAM_UID="1000"

UNLOCK_DIR="/run/exam-kiosk"
UNLOCK_FLAG="${UNLOCK_DIR}/admin-unlocked"
RESTORE_SCRIPT="/usr/local/bin/exam-kiosk/restore-desktop.sh"

mkdir -p "$UNLOCK_DIR"
chmod 755 "$UNLOCK_DIR"

touch "$UNLOCK_FLAG"
chmod 644 "$UNLOCK_FLAG"

# Close Firefox; start-exam.sh sees the flag and will not relaunch it.
pkill -TERM -u "$EXAM_UID" -x firefox 2>/dev/null || true

# Stop the clipboard-clearing loop.
pkill -TERM -u "$EXAM_UID" \
    -f '/usr/local/bin/exam-kiosk/clipboard-lockdown.sh' \
    2>/dev/null || true

# Restore XFCE settings inside the exam user's graphical session.
runuser -u "$EXAM_USER" -- env \
    HOME="/home/${EXAM_USER}" \
    USER="$EXAM_USER" \
    LOGNAME="$EXAM_USER" \
    DISPLAY=":0" \
    XAUTHORITY="/home/${EXAM_USER}/.Xauthority" \
    XDG_RUNTIME_DIR="/run/user/${EXAM_UID}" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${EXAM_UID}/bus" \
    "$RESTORE_SCRIPT"

exit 0
