#!/bin/bash

LOG="$HOME/.local/share/exam-kiosk/system-hardening.log"

mkdir -p "$(dirname "$LOG")"

log() {
    echo "$(date '+%F %T') - $1" >> "$LOG"
}

log "Applying system hardening..."

# Disable Magic SysRq
echo "kernel.sysrq = 0" > /etc/sysctl.d/99-exam.conf

# Disable Ctrl+Alt+Backspace
mkdir -p /etc/X11/xorg.conf.d

cat >/etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbOptions" ""
EndSection
EOF

# Disable USB automount
gsettings set org.gnome.desktop.media-handling automount false 2>/dev/null
gsettings set org.gnome.desktop.media-handling automount-open false 2>/dev/null

log "System hardening complete."
