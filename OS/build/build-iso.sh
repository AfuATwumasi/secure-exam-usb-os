#!/bin/bash

##############################################################################
# KNUST Secure Exam OS
# ISO Builder
##############################################################################

set -e

#-----------------------------
# Check for root
#-----------------------------
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo."
    exit 1
fi

#-----------------------------
# Directories
#-----------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

MASTER_DIR="/home/afua/KNUST-Exam-OS/iso"

CUSTOM_ROOT="$MASTER_DIR/custom-root"
CUSTOM_DISK="$MASTER_DIR/custom-disk"

WORKSPACE="$SCRIPT_DIR/workspace"

ROOT_WORK="$WORKSPACE/custom-root"
DISK_WORK="$WORKSPACE/custom-disk"

echo "===================================="
echo "KNUST Secure Exam OS Builder"
echo "===================================="

echo "[1/6] Checking master template..."

[ -d "$CUSTOM_ROOT" ] || {
    echo "custom-root missing."
    exit 1
}

[ -d "$CUSTOM_DISK" ] || {
    echo "custom-disk missing."
    exit 1
}

echo "[2/6] Cleaning workspace..."

rm -rf "$WORKSPACE"

mkdir -p "$WORKSPACE"

echo "[3/6] Copying custom-root..."

rsync -aHAX "$CUSTOM_ROOT/" "$ROOT_WORK/"

echo "[4/6] Copying custom-disk..."

rsync -a "$CUSTOM_DISK/" "$DISK_WORK/"

echo "[5/6] Checking workspace..."

[ -d "$ROOT_WORK" ] || exit 1
[ -d "$DISK_WORK" ] || exit 1

echo "[6/6] Workspace ready."

echo
echo "Workspace:"
echo "$WORKSPACE"

echo
echo "Build preparation completed."

#############################################################
# Inject system.json
#############################################################

CONFIG_DIR="$SCRIPT_DIR/config"

SYSTEM_JSON="$CONFIG_DIR/system.json"

TARGET_CONFIG="$ROOT_WORK/etc/exam-kiosk"

echo "[7/8] Installing configuration..."

if [ -f "$SYSTEM_JSON" ]; then

    mkdir -p "$TARGET_CONFIG"

    cp "$SYSTEM_JSON" \
       "$TARGET_CONFIG/system.json"

    echo "system.json installed."

else

    echo "WARNING:"
    echo "system.json not found."

fi

#############################################################
# Install Logo
#############################################################

echo "[8/10] Installing logo..."

LOGO_SOURCE="$CONFIG_DIR/logo/logo.png"
LOGO_TARGET="$ROOT_WORK/usr/share/plymouth/themes/knust-exam/logo.png"

if [ -f "$LOGO_SOURCE" ]; then
    cp "$LOGO_SOURCE" "$LOGO_TARGET"
    echo "Logo installed."
else
    echo "No custom logo supplied."
fi

#############################################################
# Install Wallpaper
#############################################################

echo "[9/10] Installing wallpaper..."

WALLPAPER_SOURCE="$CONFIG_DIR/wallpaper/knust_wallpaper1.jpeg"
WALLPAPER_TARGET="$ROOT_WORK/usr/share/backgrounds/knust-exam/knust_wallpaper1.jpeg"

if [ -f "$WALLPAPER_SOURCE" ]; then
    cp "$WALLPAPER_SOURCE" "$WALLPAPER_TARGET"
    echo "Wallpaper installed."
else
    echo "No custom wallpaper supplied."
fi

#############################################################
# Rebuild SquashFS
#############################################################

echo "[10/12] Rebuilding filesystem.squashfs..."

SQUASHFS="$DISK_WORK/casper/filesystem.squashfs"

rm -f "$SQUASHFS"

mksquashfs \
    "$ROOT_WORK" \
    "$SQUASHFS" \
    -comp xz \
    -noappend

echo "filesystem.squashfs rebuilt."

#############################################################
# Update filesystem.size
#############################################################

echo "[11/12] Updating filesystem.size..."

printf "%s" "$(sudo du -sx --block-size=1 "$ROOT_WORK" | cut -f1)" \
    > "$DISK_WORK/casper/filesystem.size"

echo "filesystem.size updated."

#############################################################
# Regenerate md5sum.txt
#############################################################

echo "[12/13] Regenerating md5sum.txt..."

cd "$DISK_WORK"

find . -type f ! -name "md5sum.txt" -print0 \
| xargs -0 md5sum > md5sum.txt

echo "md5sum.txt regenerated."


#############################################################
# Build ISO
#############################################################

echo "[13/13] Building bootable ISO..."

OUTPUT_DIR="$SCRIPT_DIR/output"
mkdir -p "$OUTPUT_DIR"

OUTPUT_ISO="$OUTPUT_DIR/KNUST-Exam-OS-Generated.iso"

sudo xorriso \
    -as mkisofs \
    -r \
    -J \
    -joliet-long \
    -l \
    -iso-level 3 \
    -V "KNUST Exam OS" \
    -o "$OUTPUT_ISO" \
    \
    --grub2-mbr "$MASTER_DIR/partition-1.img" \
    --protective-msdos-label \
    -partition_cyl_align off \
    -partition_offset 16 \
    --mbr-force-bootable \
    \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b \
    "$MASTER_DIR/partition-2.img" \
    \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    \
    -c "/boot.catalog" \
    -b "/boot/grub/i386-pc/eltorito.img" \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    \
    -eltorito-alt-boot \
    -e "--interval:appended_partition_2:all::" \
    -no-emul-boot \
    -boot-load-size 10160 \
    \
    "$DISK_WORK"

echo
echo "========================================"
echo "ISO generated successfully!"
echo "$OUTPUT_ISO"
echo "========================================"
