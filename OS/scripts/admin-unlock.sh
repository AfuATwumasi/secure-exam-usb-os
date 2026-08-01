#!/bin/bash

set -u

ACTION="/usr/local/bin/exam-kiosk/admin-unlock-action.sh"

zenity \
    --question \
    --title="Administrator Unlock" \
    --width=420 \
    --text="Unlock the examination desktop?\n\nAdministrator authentication will be required." \
    || exit 0

if pkexec "$ACTION"; then
    zenity \
        --info \
        --title="Administrator Unlock" \
        --width=380 \
        --text="The examination desktop has been unlocked."
else
    zenity \
        --error \
        --title="Unlock Failed" \
        --width=380 \
        --text="Administrator authentication failed or was cancelled."
    exit 1
fi
