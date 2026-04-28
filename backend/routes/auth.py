from flask import Blueprint, jsonify, request


auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/login")
def login():
    payload = request.get_json(silent=True) or {}
    return jsonify(
        {
            "message": "login endpoint scaffolded",
            "email": payload.get("email", ""),
        }
    )
