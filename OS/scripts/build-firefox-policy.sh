#!/bin/bash

set -euo pipefail

CONFIG="/etc/exam-kiosk/firefox/browser.json"
POLICY_DIR="/etc/firefox/policies"
POLICY_FILE="$POLICY_DIR/policies.json"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Firefox configuration not found: $CONFIG"
    exit 1
fi

if ! jq empty "$CONFIG" >/dev/null 2>&1; then
    echo "ERROR: Firefox configuration contains invalid JSON."
    exit 1
fi

HOMEPAGE=$(jq -r '.homepage // empty' "$CONFIG")

if [ -z "$HOMEPAGE" ]; then
    echo "ERROR: Firefox homepage has not been configured."
    exit 1
fi

mkdir -p "$POLICY_DIR"

jq -n \
    --arg homepage "$HOMEPAGE" \
    --argjson disable_private "$(jq '.allow_private_browsing | not' "$CONFIG")" \
    --argjson disable_printing "$(jq '.allow_printing | not' "$CONFIG")" \
    --argjson disable_devtools "$(jq '.allow_developer_tools | not' "$CONFIG")" \
    --argjson disable_telemetry "$(jq '.allow_telemetry | not' "$CONFIG")" \
    --argjson disable_updates "$(jq '.allow_browser_updates | not' "$CONFIG")" \
    --argjson disable_passwords "$(jq '.allow_password_manager | not' "$CONFIG")" \
    --argjson disable_extensions "$(jq '.allow_extensions | not' "$CONFIG")" \
    --argjson disable_downloads "$(jq '.allow_downloads | not' "$CONFIG")" \
    '{
      policies: {
        DisableAppUpdate: $disable_updates,
        DisableDeveloperTools: $disable_devtools,
        DisableFirefoxAccounts: true,
        DisableFirefoxStudies: true,
        DisableFormHistory: true,
        DisablePocket: true,
        DisablePrivateBrowsing: $disable_private,
        DisableProfileImport: true,
        DisableProfileRefresh: true,
        DisableSetDesktopBackground: true,
        DisableTelemetry: $disable_telemetry,
        DontCheckDefaultBrowser: true,
        OfferToSaveLogins: ($disable_passwords | not),
        PasswordManagerEnabled: ($disable_passwords | not),
        PrintingEnabled: ($disable_printing | not),

        Homepage: {
          URL: $homepage,
          Locked: true,
          StartPage: "homepage"
        },

        ExtensionSettings: (
          if $disable_extensions then
            {
              "*": {
                installation_mode: "blocked"
              }
            }
          else
            {}
          end
        ),

        Preferences: {
          "browser.download.useDownloadDir": {
            Value: ($disable_downloads | not),
            Status: "locked"
          },
          "browser.download.alwaysOpenPanel": {
            Value: false,
            Status: "locked"
          },
          "browser.sessionstore.resume_from_crash": {
            Value: false,
            Status: "locked"
          },
          "browser.tabs.warnOnClose": {
            Value: false,
            Status: "locked"
          },
          "devtools.policy.disabled": {
            Value: $disable_devtools,
            Status: "locked"
          }
        }
      }
    }' > "$POLICY_FILE"

chmod 644 "$POLICY_FILE"

echo "Firefox policy created successfully:"
echo "$POLICY_FILE"
