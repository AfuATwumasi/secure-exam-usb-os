from flask import Blueprint, request


auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/login', methods=['POST'])
def login():
    payload = request.get_json(silent=True) or {}

    email = str(payload.get("email", "")).strip()
    password = str(payload.get("password", "")).strip()
    role = str(payload.get("role", "student")).strip().lower()

    if not email or not password:
        return {"message": "Email and password are required"}, 400

    if role not in {"student", "admin"}:
        return {"message": "Invalid role selected"}, 400

    # Placeholder auth until DB-backed auth is implemented.
    return {
        "message": "Login successful",
        "user": {
            "email": email,
            "role": role,
        },
    }
