"""
API routes for exam configuration management and ISO build requests.
"""

import json
from datetime import datetime

from flask import Blueprint, request, jsonify
from sqlalchemy import select

from backend.config import engine
from backend.models import exam_configs, iso_builds
from backend.config_generator import (
    generate_config,
    profile_strict,
    profile_moderate,
    config_to_json,
    generate_config_id,
    ConfigValidationError,
)

config_bp = Blueprint("config", __name__, url_prefix="/api/config")


def _get_config_by_id(config_id: str) -> dict | None:
    """Fetch a config row from the database by config_id."""
    stmt = select(exam_configs).where(exam_configs.c.config_id == config_id)
    with engine.connect() as conn:
        row = conn.execute(stmt).fetchone()
    if row is None:
        return None
    return dict(row._mapping)


# ----- Configuration CRUD -----


@config_bp.route("/generate", methods=["POST"])
def generate_exam_config():
    """
    Generate a system.json configuration from admin input.
    Body (JSON):
        exam_url (required)
        exam_name (required)
        exam_duration (optional, default 120)
        course_code (optional)
        institution (optional)
        trusted_ssids (optional, list)
        allowed_domains (optional, list)
        profile (optional, "strict" | "moderate" | "custom")
        disable_terminal (optional, bool)
        disable_usb (optional, bool)
        disable_printing (optional, bool)
        disable_screenshots (optional, bool)
        kiosk_mode (optional, bool)
        allow_ethernet (optional, bool)
        exam_server (optional, str)
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Request body must be JSON"}), 400

    exam_url = data.get("exam_url")
    exam_name = data.get("exam_name")
    if not exam_url or not exam_name:
        return jsonify({"error": "exam_url and exam_name are required"}), 400

    try:
        if data.get("profile") == "strict":
            config = profile_strict(
                exam_url=exam_url,
                exam_name=exam_name,
                institution=data.get("institution", "Kwame Nkrumah University of Science and Technology"),
                trusted_ssids=data.get("trusted_ssids"),
            )
        elif data.get("profile") == "moderate":
            config = profile_moderate(
                exam_url=exam_url,
                exam_name=exam_name,
                institution=data.get("institution", "Kwame Nkrumah University of Science and Technology"),
            )
        else:
            config = generate_config(
                exam_url=exam_url,
                exam_name=exam_name,
                exam_duration=data.get("exam_duration", 120),
                course_code=data.get("course_code", ""),
                institution=data.get("institution", "Kwame Nkrumah University of Science and Technology"),
                allowed_domains=data.get("allowed_domains"),
                trusted_ssids=data.get("trusted_ssids"),
                kiosk_mode=data.get("kiosk_mode", True),
                disable_terminal=data.get("disable_terminal", True),
                disable_usb=data.get("disable_usb", False),
                disable_printing=data.get("disable_printing", True),
                disable_screenshots=data.get("disable_screenshots", True),
                allow_ethernet=data.get("allow_ethernet", True),
                profile=data.get("profile", "strict"),
                exam_server=data.get("exam_server", ""),
            )
    except ConfigValidationError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": f"Config generation failed: {str(e)}"}), 500

    return jsonify({
        "message": "Configuration generated successfully",
        "config": config,
        "config_json": config_to_json(config),
    }), 200


@config_bp.route("/save", methods=["POST"])
def save_exam_config():
    """
    Save a generated configuration to the database.
    Body (JSON):
        config (object) - the full system.json dict
        name (str) - friendly name for this config
        description (str, optional)
        course_code (str, optional)
        created_by (str, optional, default "admin")
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Request body must be JSON"}), 400

    config = data.get("config")
    if not config:
        return jsonify({"error": "'config' object is required"}), 400

    config_id = generate_config_id()
    exam_url = config.get("exam", {}).get("url", "")
    exam_name = config.get("exam", {}).get("name", "Untitled")
    exam_duration = config.get("exam", {}).get("duration", 120)
    course_code = data.get("course_code", config.get("exam", {}).get("course_code", ""))
    institution = config.get("exam", {}).get("institution", "Kwame Nkrumah University of Science and Technology")

    allowed_domains = json.dumps(config.get("exam", {}).get("allowed_domains", []))
    trusted_ssids = json.dumps([
        n.get("ssid") for n in config.get("network", {}).get("trusted_networks", [])
        if n.get("ssid")
    ])

    profile = config.get("security", {}).get("profile", "strict")
    kiosk_mode = config.get("browser", {}).get("kiosk_mode", True)
    disable_terminal = config.get("security", {}).get("desktop", {}).get("disable_terminal", True)
    disable_usb = config.get("security", {}).get("devices", {}).get("disable_usb_storage", False)
    disable_printing = config.get("security", {}).get("devices", {}).get("disable_printing", True)
    disable_screenshots = config.get("security", {}).get("browser", {}).get("disable_developer_tools", False)
    allow_ethernet = config.get("network", {}).get("connection", {}).get("allow_ethernet", True)
    exam_server = config.get("network", {}).get("verification", {}).get("exam_server", "")

    config_json = config_to_json(config)

    stmt = exam_configs.insert().values(
        config_id=config_id,
        name=data.get("name", exam_name),
        description=data.get("description", ""),
        exam_url=exam_url,
        exam_duration=exam_duration,
        course_code=course_code,
        institution=institution,
        profile=profile,
        config_json=config_json,
        allowed_domains=allowed_domains,
        trusted_ssids=trusted_ssids,
        disable_terminal=disable_terminal,
        disable_usb=disable_usb,
        disable_printing=disable_printing,
        disable_screenshots=disable_screenshots,
        kiosk_mode=kiosk_mode,
        allow_ethernet=allow_ethernet,
        exam_server=exam_server,
        created_by=data.get("created_by", "admin"),
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    with engine.begin() as conn:
        conn.execute(stmt)

    return jsonify({
        "message": "Configuration saved successfully",
        "config_id": config_id,
        "config_json": config_json,
    }), 201


@config_bp.route("/<config_id>", methods=["GET"])
def get_exam_config(config_id: str):
    """Retrieve a saved configuration by its config_id."""
    row = _get_config_by_id(config_id)
    if row is None:
        return jsonify({"error": "Configuration not found"}), 404

    # Parse stored JSON string back to dict
    config_json = row.get("config_json", "{}")
    try:
        config_dict = json.loads(config_json)
    except (json.JSONDecodeError, TypeError):
        config_dict = {}

    return jsonify({
        "config_id": row["config_id"],
        "name": row["name"],
        "description": row["description"],
        "config": config_dict,
        "profile": row["profile"],
        "created_by": row["created_by"],
        "created_at": row["created_at"].isoformat() if row.get("created_at") else None,
        "updated_at": row["updated_at"].isoformat() if row.get("updated_at") else None,
    }), 200


@config_bp.route("/", methods=["GET"])
def list_exam_configs():
    """List all saved configurations."""
    stmt = select(
        exam_configs.c.config_id,
        exam_configs.c.name,
        exam_configs.c.description,
        exam_configs.c.exam_url,
        exam_configs.c.profile,
        exam_configs.c.created_by,
        exam_configs.c.created_at,
        exam_configs.c.updated_at,
    ).order_by(exam_configs.c.created_at.desc())

    with engine.connect() as conn:
        rows = conn.execute(stmt).fetchall()

    configs = [
        {
            "config_id": r.config_id,
            "name": r.name,
            "description": r.description,
            "exam_url": r.exam_url,
            "profile": r.profile,
            "created_by": r.created_by,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "updated_at": r.updated_at.isoformat() if r.updated_at else None,
        }
        for r in rows
    ]

    return jsonify({"configs": configs}), 200


@config_bp.route("/<config_id>", methods=["DELETE"])
def delete_exam_config(config_id: str):
    """Delete a saved configuration."""
    stmt = select(exam_configs).where(exam_configs.c.config_id == config_id)
    with engine.connect() as conn:
        row = conn.execute(stmt).fetchone()

    if row is None:
        return jsonify({"error": "Configuration not found"}), 404

    delete_stmt = exam_configs.delete().where(exam_configs.c.config_id == config_id)
    with engine.begin() as conn:
        conn.execute(delete_stmt)

    return jsonify({"message": "Configuration deleted successfully"}), 200


# ----- ISO Build Request Endpoints -----


@config_bp.route("/<config_id>/build", methods=["POST"])
def request_iso_build(config_id: str):
    """
    Request an ISO build for a saved configuration.
    The ISO Builder Service will pick up this request.
    """
    row = _get_config_by_id(config_id)
    if row is None:
        return jsonify({"error": "Configuration not found"}), 404

    from backend.iso_builder import generate_build_id

    build_id = generate_build_id()

    stmt = iso_builds.insert().values(
        config_id=config_id,
        build_id=build_id,
        status="pending",
        requested_by=request.headers.get("X-User", "admin"),
        created_at=datetime.utcnow(),
    )

    with engine.begin() as conn:
        conn.execute(stmt)

    return jsonify({
        "message": "ISO build requested",
        "build_id": build_id,
        "status": "pending",
    }), 201


@config_bp.route("/builds/<build_id>", methods=["GET"])
def get_build_status(build_id: str):
    """Get the status of an ISO build."""
    stmt = select(iso_builds).where(iso_builds.c.build_id == build_id)
    with engine.connect() as conn:
        row = conn.execute(stmt).fetchone()

    if row is None:
        return jsonify({"error": "Build not found"}), 404

    return jsonify({
        "build_id": row.build_id,
        "config_id": row.config_id,
        "status": row.status,
        "iso_filename": row.iso_filename,
        "sha256_hash": row.sha256_hash,
        "error_message": row.error_message,
        "requested_by": row.requested_by,
        "created_at": row.created_at.isoformat() if row.created_at else None,
        "completed_at": row.completed_at.isoformat() if row.completed_at else None,
    }), 200


@config_bp.route("/builds", methods=["GET"])
def list_builds():
    """List all ISO builds."""
    stmt = select(
        iso_builds.c.build_id,
        iso_builds.c.config_id,
        iso_builds.c.status,
        iso_builds.c.iso_filename,
        iso_builds.c.sha256_hash,
        iso_builds.c.error_message,
        iso_builds.c.requested_by,
        iso_builds.c.created_at,
        iso_builds.c.completed_at,
    ).order_by(iso_builds.c.created_at.desc())

    with engine.connect() as conn:
        rows = conn.execute(stmt).fetchall()

    builds = [
        {
            "build_id": r.build_id,
            "config_id": r.config_id,
            "status": r.status,
            "iso_filename": r.iso_filename,
            "sha256_hash": r.sha256_hash,
            "error_message": r.error_message,
            "requested_by": r.requested_by,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "completed_at": r.completed_at.isoformat() if r.completed_at else None,
        }
        for r in rows
    ]

    return jsonify({"builds": builds}), 200
