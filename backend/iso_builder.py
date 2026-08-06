"""
ISO Builder Service (stub).

This module will handle:
  1. Mounting/extracting the master ISO template
  2. Injecting system.json into /etc/exam-kiosk/
  3. Rebuilding squashfs
  4. Generating a new bootable ISO
  5. Calculating SHA-256 checksum
  6. Storing the output ISO

The full implementation requires:
  - xorriso
  - squashfs-tools (mksquashfs, unsquashfs)
  - genisoimage
  - The master ISO template file

For now this provides the interface and build ID generation
so the rest of the backend can call it when ready.
"""

import uuid
import json
import requests
import subprocess
from datetime import datetime
from typing import Optional
from pathlib import Path
from sqlalchemy import update
from backend.config import engine
from backend.models import iso_builds

# ---- Configuration ----

# Directory where master ISO templates are stored
MASTER_ISO_DIR = Path("storage/master-isos")
MASTER_ISO_DIR.mkdir(parents=True, exist_ok=True)

# Directory where generated ISOs will be placed
OUTPUT_ISO_DIR = Path("storage/generated-isos")
OUTPUT_ISO_DIR.mkdir(parents=True, exist_ok=True)

# Directory for temporary build workspace
BUILD_WORKSPACE = Path("storage/build-workspace")
BUILD_WORKSPACE.mkdir(parents=True, exist_ok=True)

# Path to the build configuration file used by build-iso.sh
SYSTEM_JSON_PATH = Path("OS/build/config/system.json")

# Path to the build script
BUILD_SCRIPT = Path("OS/build/build-iso.sh")

# ---- Build ID ----

def generate_build_id() -> str:
    """Generate a unique ISO build identifier."""
    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    short_uuid = uuid.uuid4().hex[:8]
    return f"build-{timestamp}-{short_uuid}"


# ---- ISO Build Process (Stub) ----

class ISOBuildError(Exception):
    """Raised when ISO build fails."""
    pass


def build_iso(
    config_json: str,
    config_id: str,
    build_id: str,
    master_iso_path: Optional[Path] = None,
    wallpaper_path: Optional[Path] = None,
    logo_path: Optional[Path] = None,   
) -> dict:
    """
    Build a customized ISO from a master template.

    Args:
        config_json: The system.json configuration as a JSON string.
        config_id: The configuration ID for tracking.
        build_id: The build ID for this build.
        master_iso_path: Path to the master ISO file.
            If None, uses the latest ISO in MASTER_ISO_DIR.
        wallpaper_path: Optional custom wallpaper to inject.
        logo_path: Optional custom logo to inject.

    Returns:
        dict with:
            - success: bool
            - iso_path: str (path to generated ISO)
            - sha256: str
            - size_bytes: int
            - error: str (if failed)

    Raises:
        ISOBuildError: If the build process fails.
    """
    # TODO: Implement the full ISO build process.
    # Steps:
    # 1. Validate that master ISO exists
    # 2. Create a working copy of the master ISO
    # 3. Extract squashfs from the ISO using unsquashfs
    # 4. Write system.json to /etc/exam-kiosk/system.json in the extracted fs
    # 5. Optionally replace branding assets
    # 6. Rebuild squashfs using mksquashfs
    # 7. Rebuild ISO using xorriso or genisoimage
    # 8. Calculate SHA-256 checksum
    # 9. Move output ISO to OUTPUT_ISO_DIR
    # 10. Clean up workspace
    with engine.begin() as conn:
        conn.execute(
            update(iso_builds)
            .where(iso_builds.c.build_id == build_id)
            .values(
                status="Building"
            )
        )    

    # Ensure the config directory exists
    SYSTEM_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)

    # Validate that config_json is valid JSON
    config_data = json.loads(config_json)

    # Write the configuration that build-iso.sh will use
    with open(SYSTEM_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(config_data, f, indent=2)

    print(f"[ISO BUILDER] Wrote configuration to {SYSTEM_JSON_PATH}")

    # Verify the file exists
    if not SYSTEM_JSON_PATH.exists():
        raise ISOBuildError("Failed to write system.json")

    print("[ISO BUILDER] system.json successfully written.")

    response = requests.post(
        "http://192.168.56.101:5001/build",
        timeout=1800  # Allow up to 30 minutes for ISO generation
    )

    response.raise_for_status()

    build_result = response.json()

    if not build_result.get("success"):
        raise ISOBuildError(
            build_result.get("stderr", "Unknown build error")
        )

    print("[ISO BUILDER] Ubuntu build completed successfully.")

    return {
        "success": True,
        "iso_path": build_result["iso_path"],
    }



def get_build_output_path(build_id: str) -> Path:
    """Get the expected output path for a generated ISO."""
    return OUTPUT_ISO_DIR / f"{build_id}.iso"


def get_build_log_path(build_id: str) -> Path:
    """Get the path for a build log file."""
    return BUILD_WORKSPACE / f"{build_id}.log"


# TODO:
# Replace stub implementation with the production ISO build pipeline.
# This will invoke the Cubic/custom build scripts, generate the ISO,
# compute the SHA-256 checksum, store the artifact,
# and update the iso_builds table status.   