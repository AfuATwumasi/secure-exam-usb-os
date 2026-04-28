from flask import Blueprint, jsonify


exam_bp = Blueprint("exam", __name__)


@exam_bp.get("/status")
def status():
    return jsonify({"message": "exam routes scaffolded"})
