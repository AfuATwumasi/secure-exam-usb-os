"""
API routes for exam configuration management and ISO build requests.
"""

import json
from datetime import datetime

from flask import Blueprint, request, jsonify
from sqlalchemy import select

from backend.config import engine
from backend.models import admins, exam_configurations, iso_artifacts, iso_builds
from backend.config_generator import (
    generate_all_configs,
    config_to_json,
    generate_config_id,
    ConfigValidationError,
)

config_bp = Blueprint("config", __name__, url_prefix="/api/config")


def _get_config_row(config_uuid: str):
    """Fetch a configuration row by config_uuid."""
    stmt = select(exam_configurations).where(
        exam_configurations.c.config_uuid == config_uuid
    )
    with engine.connect() as conn:
        return conn.execute(stmt).fetchone()


# ----- Configuration CRUD -----


@config_bp.route("/generate", methods=["POST"])
def generate_exam_config():
    data = request.get_json(silent=True) or {}
    exam_url = data.get("exam_url")
    exam_name = data.get("exam_name")
    if not exam_url or not exam_name:
        return jsonify({"error": "exam_url and exam_name are required"}), 400

    try:
        result = generate_all_configs(
            exam_url=exam_url,
            exam_name=exam_name,
            exam_duration=data.get("exam_duration", 120),
            course_code=data.get("course_code", ""),
            institution=data.get("institution",
                "Kwame Nkrumah University of Science and Technology"),
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
        "config": result["system_config"],
        "config_json": result["system_json"],
        "security_config": result["security_config"],
        "security_json": result["security_json"],
    }), 200


@config_bp.route("/save", methods=["POST"])
def save_exam_config():
    data = request.get_json(silent=True) or {}
    config = data.get("config")
    if not config:
        return jsonify({"error": "'config' object is required"}), 400

    created_by = data.get("created_by") or data.get("admin_id")
    if created_by in (None, ""):
        created_by = None
    else:
        try:
            created_by = int(created_by)
        except (TypeError, ValueError):
            return jsonify({"error": "created_by must be a numeric admin id"}), 400

    config_uuid = generate_config_id()
    exam_url = config.get("exam", {}).get("url", "")
    exam_name = config.get("exam", {}).get("name", "Untitled")
    duration = config.get("exam", {}).get("duration", 120)
    course_code = data.get("course_code",
        config.get("exam", {}).get("course_code", ""))

    config_json = config_to_json(config)

    stmt = exam_configurations.insert().values(
        config_uuid=config_uuid,
        exam_name=data.get("name", exam_name),
        exam_url=exam_url,
        duration=duration,
        exam_source="MOODLE",
        created_by=created_by,
        config_json=config_json,
        created_at=datetime.utcnow(),
    )

    with engine.begin() as conn:
        conn.execute(stmt)

    return jsonify({
        "message": "Configuration saved successfully",
        "config_id": config_uuid,
        "config_json": config_json,
    }), 201


@config_bp.route("/<config_uuid>", methods=["GET"])
def get_exam_config(config_uuid: str):
    row = _get_config_row(config_uuid)
    if row is None:
        return jsonify({"error": "Configuration not found"}), 404

    try:
        config_dict = json.loads(row.config_json)
    except (json.JSONDecodeError, TypeError):
        config_dict = {}

    return jsonify({
        "config_id": row.config_uuid,
        "name": row.exam_name,
        "exam_url": row.exam_url,
        "config": config_dict,
        "created_at": row.created_at.isoformat() if row.created_at else None,
    }), 200


@config_bp.route("/", methods=["GET"])
def list_exam_configs():
    stmt = select(
        exam_configurations.c.config_uuid,
        exam_configurations.c.exam_name,
        exam_configurations.c.exam_url,
        exam_configurations.c.duration,
        exam_configurations.c.created_at,
    ).order_by(exam_configurations.c.created_at.desc())

    with engine.connect() as conn:
        rows = conn.execute(stmt).fetchall()

    configs = [
        {
            "config_id": r.config_uuid,
            "name": r.exam_name,
            "exam_url": r.exam_url,
            "duration": r.duration,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in rows
    ]

    return jsonify({"configs": configs}), 200


@config_bp.route("/<config_uuid>", methods=["DELETE"])
def delete_exam_config(config_uuid: str):
    row = _get_config_row(config_uuid)
    if row is None:
        return jsonify({"error": "Configuration not found"}), 404

    delete_stmt = exam_configurations.delete().where(
        exam_configurations.c.config_uuid == config_uuid
    )
    with engine.begin() as conn:
        conn.execute(delete_stmt)

    return jsonify({"message": "Configuration deleted successfully"}), 200


# ----- ISO Build Request Endpoints -----


@config_bp.route("/<config_uuid>/build", methods=["POST"])
def request_iso_build(config_uuid: str):
    row = _get_config_row(config_uuid)
    if row is None:
        return jsonify({"error": "Configuration not found"}), 404

    admin_id = request.get_json(silent=True) or {}
    admin_id = admin_id.get("admin_id") or row.created_by
    if admin_id in (None, ""):
        return jsonify({"error": "An admin id is required to build an ISO"}), 400
    try:
        admin_id = int(admin_id)
    except (TypeError, ValueError):
        return jsonify({"error": "admin_id must be numeric"}), 400

    from backend.iso_builder import generate_build_id

    build_id = generate_build_id()

    stmt = iso_builds.insert().values(
        build_id=build_id,
        config_id=row.config_uuid,
        requested_by=str(admin_id),
        status="Pending",
        created_at=datetime.utcnow(),
    )

    with engine.begin() as conn:
        conn.execute(stmt)

    return jsonify({
        "message": "ISO build requested",
        "build_id": build_id,
        "admin_id": admin_id,
        "status": "Pending",
    }), 201


@config_bp.route("/builds/<build_id>", methods=["GET"])
def get_build_status(build_id: str):
    stmt = select(iso_builds).where(iso_builds.c.build_id == build_id)
    with engine.connect() as conn:
        row = conn.execute(stmt).fetchone()

    if row is None:
        return jsonify({"error": "Build not found"}), 404

    return jsonify({
        "build_id": row.build_id,
        "config_id": row.config_id,
        "status": row.status,
        "iso_name": row.iso_filename,
        "iso_size": row.iso_size_bytes,
        "error_message": row.error_message,
        "created_at": row.created_at.isoformat() if row.created_at else None,
        "completed_at": row.completed_at.isoformat() if row.completed_at else None,
    }), 200


@config_bp.route("/builds", methods=["GET"])
def list_builds():
    stmt = select(
        iso_builds.c.build_id,
        iso_builds.c.config_id,
        iso_builds.c.status,
        iso_builds.c.iso_filename,
        iso_builds.c.iso_size_bytes,
        iso_builds.c.error_message,
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
            "iso_name": r.iso_filename,
            "iso_size": r.iso_size_bytes,
            "error_message": r.error_message,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "completed_at": r.completed_at.isoformat() if r.completed_at else None,
        }
        for r in rows
    ]

    return jsonify({"builds": builds}), 200