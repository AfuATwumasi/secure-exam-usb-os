#!/bin/bash

set -u

CONFIG_LOADER="/usr/local/lib/exam-kiosk/config-loader.sh"

if [ ! -r "$CONFIG_LOADER" ]; then
    echo "Configuration loader is missing."
    exit 1
fi

source "$CONFIG_LOADER"

if ! load_exam_config; then
    echo "Unable to load the examination configuration."
    exit 1
fi

echo "============================================"
echo "       KNUST Secure Exam OS Configuration"
echo "============================================"
echo
echo "Product name       : $PRODUCT_NAME"
echo "Institution        : $INSTITUTION_NAME"
echo "Build version      : $BUILD_VERSION"
echo
echo "Exam name          : $EXAM_NAME"
echo "Exam URL           : $EXAM_URL"
echo "Security profile   : $EXAM_PROFILE"
echo
echo "Exam user          : $EXAM_USERNAME"
echo "Administrator      : $ADMIN_USERNAME"
echo "Automatic login    : $EXAM_AUTOLOGIN"
echo
echo "Network mode       : $NETWORK_MODE"
echo "Internet required  : $REQUIRE_INTERNET"
echo "Exam server        : $EXAM_SERVER"
echo "Network timeout    : ${NETWORK_TIMEOUT} seconds"
echo
echo "Trusted networks:"
get_trusted_ssids | sed 's/^/  - /'
echo
echo "Terminal disabled  : $DISABLE_TERMINAL"
echo "Alt+Tab disabled   : $DISABLE_ALT_TAB"
echo "Super key disabled : $DISABLE_SUPER_KEY"
echo "USB storage blocked: $DISABLE_USB_STORAGE"
echo
echo "============================================"
