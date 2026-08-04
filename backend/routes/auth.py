from datetime import datetime

from flask import Blueprint, request, jsonify
from sqlalchemy import select, update
from werkzeug.security import check_password_hash

from backend.auth_setup import DEFAULT_ADMIN_EMAIL, DEFAULT_ADMIN_PASSWORD
from backend.config import engine
from backend.models import admins


auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/login', methods=['POST'])
def login():
    payload = request.get_json(silent=True) or {}

    email = str(payload.get("email", "")).strip()
    password = str(payload.get("password", "")).strip()
    role = str(payload.get("role", "admin")).strip().lower()

    if not email or not password:
        return {"message": "Email and password are required"}, 400

    if role != "admin":
        return {"message": "Admin access is required"}, 403

    normalized_email = email.lower()
    if normalized_email in {DEFAULT_ADMIN_EMAIL.lower(), "admin"} and password == DEFAULT_ADMIN_PASSWORD:
        email = DEFAULT_ADMIN_EMAIL

    stmt = select(admins).where(
        (admins.c.email == email) | (admins.c.username == email)
    )

    with engine.connect() as conn:
        row = conn.execute(stmt).fetchone()

    if row is None:
        return {"message": "Invalid administrator credentials"}, 401

    try:
        password_matches = check_password_hash(row.password_hash, password)
    except ValueError:
        password_matches = False

    if not password_matches:
        return {"message": "Invalid administrator credentials"}, 401

    with engine.begin() as conn:
        conn.execute(
            update(admins)
            .where(admins.c.admin_id == row.admin_id)
            .values(last_login=datetime.utcnow())
        )

    return jsonify({
        "message": "Login successful",
        "user": {
            "admin_id": row.admin_id,
            "username": row.username,
            "email": row.email,
            "role": row.role,
        },
    })
