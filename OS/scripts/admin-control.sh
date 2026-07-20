#!/bin/bash

set -u

BIN_DIR="/usr/local/bin/exam-kiosk"
CONFIG_LOADER="/usr/local/lib/exam-kiosk/config-loader.sh"

if [ ! -r "$CONFIG_LOADER" ]; then
    echo "Configuration loader is missing."
    exit 1
fi

source "$CONFIG_LOADER"
load_exam_config || exit 1

while true; do
    clear

    echo "================================================"
    echo "          KNUST Secure Exam OS Admin"
    echo "================================================"
    echo
    echo "Product       : $PRODUCT_NAME"
    echo "Build version : $BUILD_VERSION"
    echo "Exam          : $EXAM_NAME"
    echo
    echo "1. Show configuration"
    echo "2. Validate configuration"
    echo "3. Generate diagnostic report"
    echo "4. Restart Network Manager"
    echo "5. Restart display manager"
    echo "6. Reboot computer"
    echo "7. Shut down computer"
    echo "8. Exit"
    echo

    read -r -p "Select an option: " OPTION

    case "$OPTION" in
        1)
            "$BIN_DIR/show-config.sh"
            read -r -p "Press Enter to continue..."
            ;;

        2)
            "$BIN_DIR/validate-config.sh"
            read -r -p "Press Enter to continue..."
            ;;

        3)
            "$BIN_DIR/generate-diagnostics.sh"
            read -r -p "Press Enter to continue..."
            ;;

        4)
            systemctl restart NetworkManager
            echo "Network Manager restarted."
            sleep 2
            ;;

        5)
            systemctl restart lightdm
            exit 0
            ;;

        6)
            systemctl reboot
            ;;

        7)
            systemctl poweroff
            ;;

        8)
            exit 0
            ;;

        *)
            echo "Invalid option."
            sleep 2
            ;;
    esac
done
