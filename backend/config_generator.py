"""
Configuration Generator for KNUST Secure Exam OS.

Generates a valid system.json matching the schema expected by
the OS's config-loader.sh at /etc/exam-kiosk/system.json.
"""

import json
import uuid
import re
from datetime import datetime
from typing import Any, Optional


# ----- Schema defaults (mirrors OS/config/system.example.json) -----

DEFAULT_CONFIG: dict[str, Any] = {
    "schema_version": "1.0",
    "exam": {
        "name": "KNUST Secure Examination",
        "url": "",
        "institution": "Kwame Nkrumah University of Science and Technology",
        "allowed_domains": [],
    },
    "browser": {
        "kiosk_mode": True,
        "restart_if_closed": True,
        "startup_delay_seconds": 8,
        "network_wait_seconds": 60,
        "disable_downloads": True,
        "disable_printing": True,
        "disable_private_browsing": True,
        "disable_password_saving": True,
        "disable_browser_updates": True,
    },
    "system": {
        "hostname": "knust-exam-os",
        "live_username": "exam",
        "autologin": True,
        "build_version": "1.0.0",
    },
    "network": {
        "mode": "trusted-network",
        "connection": {
            "allow_wifi": True,
            "allow_ethernet": True,
            "allow_manual_configuration": False,
        },
        "trusted_networks": [],
        "verification": {
            "require_trusted_network": False,
            "require_internet": True,
            "require_exam_server": False,
            "internet_test_host": "1.1.1.1",
            "exam_server": "",
            "timeout_seconds": 20,
        },
        "filtering": {
            "enable_domain_filtering": True,
            "block_other_traffic": False,
        },
        "allowed_domains": [],
        "allowed_ports": [53, 80, 443],
    },
    "security": {
        "profile": "strict",
        "desktop": {
            "disable_terminal": True,
            "disable_file_manager": True,
            "disable_settings": True,
            "disable_task_manager": True,
            "disable_desktop_icons": True,
            "disable_right_click": True,
            "hide_panel": True,
        },
        "keyboard": {
            "disable_alt_tab": True,
            "disable_ctrl_alt_t": True,
            "disable_super_key": True,
            "disable_run_dialog": True,
            "disable_workspace_switching": True,
            "disable_virtual_terminals": True,
        },
        "devices": {
            "disable_usb_storage": False,
            "disable_bluetooth": True,
            "disable_camera": False,
            "disable_printing": True,
        },
        "session": {
            "disable_logout": True,
            "disable_shutdown": True,
            "disable_suspend": True,
            "disable_screen_lock": True,
            "clear_session_on_exit": True,
        },
        "browser": {
            "disable_developer_tools": True,
            "disable_view_source": True,
            "disable_new_windows": True,
            "disable_extensions": True,
            "disable_clipboard": False,
        },
    },
    "branding": {
        "product_name": "KNUST Secure Exam OS",
        "short_name": "KNUST Exam OS",
        "institution": "Kwame Nkrumah University of Science and Technology",
        "wallpaper": "/usr/share/backgrounds/knust-exam/knust_wallpaper1.jpeg",
        "desktop_background_style": "zoomed",
        "show_desktop_branding": True,
        "show_build_version": True,
    },
    "administrator": {
        "username": "admin",
        "allow_tty_login": True,
        "allow_gui_login": True,
        "allow_recovery": True,
    },
    "student": {
        "username": "exam",
        "autologin": True,
    },
}

# ----- Security-only defaults (for separate security.json) -----

DEFAULT_SECURITY_CONFIG: dict[str, Any] = {
    "desktop": {
        "disable_desktop_icons": True,
        "disable_right_click": True,
        "hide_panel": True,
    },
    "keyboard": {
        "disable_ctrl_alt_t": True,
        "disable_run_dialog": True,
        "disable_super_key": True,
        "disable_alt_tab": True,
        "disable_alt_f4": True,
        "disable_print_screen": True,
        "disable_workspace_switching": True,
    },
    "session": {
        "disable_screen_lock": True,
        "disable_suspend": True,
    },
    "browser": {
        "disable_clipboard": False,
    },
}


# ----- Validation -----

class ConfigValidationError(Exception):
    """Raised when config validation fails."""
    pass


def validate_url(url: str) -> bool:
    """Basic URL validation."""
    pattern = r"^https?://[^\s/$.?#].[^\s]*$"
    return bool(re.match(pattern, url))


def validate_domain(domain: str) -> bool:
    """Basic domain/hostname validation."""
    pattern = r"^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
    return bool(re.match(pattern, domain))


def validate_config(config: dict) -> list[str]:
    """
    Validate a config dict against the required schema.
    Returns a list of error messages (empty = valid).
    """
    errors: list[str] = []

    # schema_version
    if not config.get("schema_version"):
        errors.append("schema_version is required")

    # exam
    exam = config.get("exam", {})
    if not exam.get("url"):
        errors.append("exam.url is required")
    elif not validate_url(exam["url"]):
        errors.append("exam.url must be a valid http/https URL")
    if not exam.get("name"):
        errors.append("exam.name is required")

    # browser
    browser = config.get("browser", {})
    if browser.get("startup_delay_seconds", 0) < 0:
        errors.append("browser.startup_delay_seconds must be >= 0")
    if browser.get("network_wait_seconds", 0) < 0:
        errors.append("browser.network_wait_seconds must be >= 0")

    # network
    network = config.get("network", {})
    trusted = network.get("trusted_networks", [])
    for i, net in enumerate(trusted):
        if not net.get("ssid"):
            errors.append(f"network.trusted_networks[{i}].ssid is required")

    verification = network.get("verification", {})
    if verification.get("timeout_seconds", 0) < 1:
        errors.append("network.verification.timeout_seconds must be >= 1")

    filtering = network.get("filtering", {})
    if filtering.get("enable_domain_filtering"):
        allowed_domains = network.get("allowed_domains", [])
        if not allowed_domains:
            errors.append(
                "network.allowed_domains is required when "
                "domain filtering is enabled"
            )

    # security
    security = config.get("security", {})
    valid_profiles = ["strict", "moderate", "custom"]
    if security.get("profile") not in valid_profiles:
        errors.append(
            f"security.profile must be one of {valid_profiles}"
        )

    # branding
    branding = config.get("branding", {})
    if not branding.get("product_name"):
        errors.append("branding.product_name is required")
    if not branding.get("institution"):
        errors.append("branding.institution is required")

    # administrator
    admin = config.get("administrator", {})
    if not admin.get("username"):
        errors.append("administrator.username is required")

    # student
    student = config.get("student", {})
    if not student.get("username"):
        errors.append("student.username is required")

    return errors


# ----- Config Generation -----

def generate_config(
    exam_url: str,
    exam_name: str,
    exam_duration: int = 120,
    course_code: str = "",
    institution: str = "Kwame Nkrumah University of Science and Technology",
    allowed_domains: Optional[list[str]] = None,
    trusted_ssids: Optional[list[str]] = None,
    kiosk_mode: bool = True,
    fullscreen: bool = True,
    disable_terminal: bool = True,
    disable_usb: bool = False,
    disable_printing: bool = True,
    disable_screenshots: bool = True,
    allow_ethernet: bool = True,
    wallpaper: str = "/usr/share/backgrounds/knust-exam/knust_wallpaper1.jpeg",
    logo: str = "",
    profile: str = "strict",
    admin_username: str = "admin",
    student_username: str = "exam",
    exam_server: str = "",
    heartbeat_interval: int = 30,
) -> dict[str, Any]:
    """
    Generate a complete system.json config from simplified parameters.
    This is the main entry point for the backend.

    Args:
        exam_url: The Moodle/examination URL.
        exam_name: Name of the examination.
        exam_duration: Duration in minutes.
        course_code: Course code (optional).
        institution: Institution name.
        allowed_domains: List of allowed domains for network filtering.
        trusted_ssids: List of trusted Wi-Fi SSIDs.
        kiosk_mode: Whether to lock browser in kiosk mode.
        fullscreen: Whether to launch browser fullscreen.
        disable_terminal: Block terminal access.
        disable_usb: Block USB storage.
        disable_printing: Block printing.
        disable_screenshots: Block screenshots.
        allow_ethernet: Allow ethernet connections.
        wallpaper: Path to wallpaper in the OS.
        logo: Path to logo in the OS.
        profile: Security profile (strict, moderate, custom).
        admin_username: Admin account username.
        student_username: Student account username.
        exam_server: Exam server hostname for connectivity checks.
        heartbeat_interval: Heartbeat interval in seconds.

    Returns:
        A complete config dict ready for JSON serialization.

    Raises:
        ConfigValidationError: If generated config fails validation.
    """
    config = DEFAULT_CONFIG.copy()
    config["schema_version"] = "1.0"
    config["system"]["build_version"] = "1.0.0"

    # --- Exam section ---
    config["exam"]["name"] = exam_name
    config["exam"]["url"] = exam_url
    config["exam"]["institution"] = institution
    if allowed_domains:
        config["exam"]["allowed_domains"] = allowed_domains
    else:
        # Auto-extract domain from URL
        from urllib.parse import urlparse
        parsed = urlparse(exam_url)
        if parsed.netloc:
            domain = parsed.netloc
            config["exam"]["allowed_domains"] = [domain]
            # Also populate network allowed_domains if empty
            if not config["network"]["allowed_domains"]:
                config["network"]["allowed_domains"] = [domain]

    # --- Browser section ---
    config["browser"]["kiosk_mode"] = kiosk_mode
    if not kiosk_mode:
        config["browser"]["kiosk_mode"] = False

    # --- Network section ---
    if trusted_ssids:
        config["network"]["trusted_networks"] = [
            {"ssid": ssid, "connection_type": "wifi"}
            for ssid in trusted_ssids
        ]
        config["network"]["verification"]["require_trusted_network"] = True

    config["network"]["connection"]["allow_ethernet"] = allow_ethernet

    if allowed_domains:
        config["network"]["allowed_domains"] = allowed_domains

    if exam_server:
        config["network"]["verification"]["require_exam_server"] = True
        config["network"]["verification"]["exam_server"] = exam_server
        if exam_server not in (config["network"]["allowed_domains"] or []):
            config["network"]["allowed_domains"].append(exam_server)

    # --- Security section ---
    config["security"]["profile"] = profile
    config["security"]["desktop"]["disable_terminal"] = disable_terminal
    config["security"]["devices"]["disable_usb_storage"] = disable_usb
    config["security"]["devices"]["disable_printing"] = disable_printing

    # Map disable_screenshots -> browser config
    if disable_screenshots:
        config["security"]["browser"]["disable_developer_tools"] = True
        config["security"]["browser"]["disable_view_source"] = True

    # --- Branding section ---
    if wallpaper:
        config["branding"]["wallpaper"] = wallpaper
    if logo:
        config["branding"]["logo"] = logo

    # --- Administrator section ---
    config["administrator"]["username"] = admin_username

    # --- Student section ---
    config["student"]["username"] = student_username

    # Validate
    errors = validate_config(config)
    if errors:
        raise ConfigValidationError("; ".join(errors))

    return config


def generate_config_minimal(
    exam_url: str,
    exam_name: str,
    **overrides: Any,
) -> dict[str, Any]:
    """
    Generate config with minimal required params + any overrides.
    Overrides can be nested dict paths like:
        {"security.desktop.disable_terminal": False}
    """
    config = generate_config(exam_url=exam_url, exam_name=exam_name)

    for key, value in overrides.items():
        parts = key.split(".")
        target = config
        for part in parts[:-1]:
            if part not in target:
                target[part] = {}
            target = target[part]
        target[parts[-1]] = value

    errors = validate_config(config)
    if errors:
        raise ConfigValidationError("; ".join(errors))

    return config


def config_to_json(config: dict[str, Any], indent: int = 2) -> str:
    """Serialize config to pretty-printed JSON string."""
    return json.dumps(config, indent=indent, ensure_ascii=False)


# ----- Configuration Profile Presets -----

def profile_strict(
    exam_url: str,
    exam_name: str,
    institution: str = "Kwame Nkrumah University of Science and Technology",
    trusted_ssids: Optional[list[str]] = None,
) -> dict[str, Any]:
    """Generate a strict security profile config."""
    return generate_config(
        exam_url=exam_url,
        exam_name=exam_name,
        institution=institution,
        trusted_ssids=trusted_ssids,
        kiosk_mode=True,
        fullscreen=True,
        disable_terminal=True,
        disable_usb=True,
        disable_printing=True,
        disable_screenshots=True,
        profile="strict",
    )


def profile_moderate(
    exam_url: str,
    exam_name: str,
    institution: str = "Kwame Nkrumah University of Science and Technology",
) -> dict[str, Any]:
    """Generate a moderate security profile config."""
    return generate_config(
        exam_url=exam_url,
        exam_name=exam_name,
        institution=institution,
        kiosk_mode=True,
        fullscreen=True,
        disable_terminal=True,
        disable_usb=False,
        disable_printing=False,
        disable_screenshots=True,
        profile="moderate",
    )


# ----- generate_security_config (for separate /etc/exam-kiosk/security.json) -----

def generate_security_config(
    system_config: dict,
) -> dict[str, Any]:
    """
    Extract the security section from a system.json config and produce
    a separate security.json matching what lockdown.sh expects.

    This is needed because Afua refactored lockdown.sh to read from
    /etc/exam-kiosk/security.json instead of system.json.
    """
    security = system_config.get("security", {})

    result = DEFAULT_SECURITY_CONFIG.copy()

    # Map system.json security fields -> security.json fields
    desktop = security.get("desktop", {})
    result["desktop"]["disable_desktop_icons"] = desktop.get("disable_desktop_icons", True)
    result["desktop"]["disable_right_click"] = desktop.get("disable_right_click", True)
    result["desktop"]["hide_panel"] = desktop.get("hide_panel", True)

    keyboard = security.get("keyboard", {})
    result["keyboard"]["disable_ctrl_alt_t"] = keyboard.get("disable_ctrl_alt_t", True)
    result["keyboard"]["disable_run_dialog"] = keyboard.get("disable_run_dialog", True)
    result["keyboard"]["disable_super_key"] = keyboard.get("disable_super_key", True)
    result["keyboard"]["disable_alt_tab"] = keyboard.get("disable_alt_tab", True)
    result["keyboard"]["disable_workspace_switching"] = keyboard.get("disable_workspace_switching", True)

    session = security.get("session", {})
    result["session"]["disable_screen_lock"] = session.get("disable_screen_lock", True)
    result["session"]["disable_suspend"] = session.get("disable_suspend", True)

    browser_sec = security.get("browser", {})
    result["browser"]["disable_clipboard"] = browser_sec.get("disable_clipboard", False)

    return result


def generate_all_configs(
    exam_url: str,
    exam_name: str,
    **kwargs: Any,
) -> dict[str, Any]:
    """
    Generate both system.json and security.json configs.

    Returns:
        dict with:
            - system_config: the full system.json dict
            - security_config: the separate security.json dict
            - system_json: pretty-printed system.json string
            - security_json: pretty-printed security.json string
    """
    system_config = generate_config(exam_url=exam_url, exam_name=exam_name, **kwargs)
    security_config = generate_security_config(system_config)

    return {
        "system_config": system_config,
        "security_config": security_config,
        "system_json": config_to_json(system_config),
        "security_json": config_to_json(security_config),
    }


# ----- Generate unique config ID -----

def generate_config_id() -> str:
    """Generate a unique configuration identifier."""
    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    short_uuid = uuid.uuid4().hex[:8]
    return f"cfg-{timestamp}-{short_uuid}"
