from flask import Blueprint


exam_bp = Blueprint('exam', __name__)


@exam_bp.route('/questions', methods=['GET'])
def get_questions():
    return {"questions": ["Q1", "Q2"]}


@exam_bp.route('/submit', methods=['POST'])
def submit():
    return {"message": "Submitted successfully"}
