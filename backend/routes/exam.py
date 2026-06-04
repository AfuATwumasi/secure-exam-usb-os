from flask import Blueprint, request


exam_bp = Blueprint('exam', __name__)


SAMPLE_QUESTIONS = [
    {
        "id": 1,
        "question": "What is 2 + 2?",
        "options": ["2", "3", "4", "5"],
    },
    {
        "id": 2,
        "question": "Which of these is a prime number?",
        "options": ["8", "9", "11", "12"],
    },
    {
        "id": 3,
        "question": "What is the SI unit of force?",
        "options": ["Joule", "Watt", "Newton", "Pascal"],
    },
]


SAMPLE_EXAMS = [
    {
        "id": "math-101",
        "title": "Mathematics 101",
        "description": "Basic algebra and arithmetic concepts",
        "question_count": 10,
        "duration_minutes": 30,
        "pass_mark": 70,
    },
    {
        "id": "science-intro",
        "title": "General Science",
        "description": "Introduction to scientific concepts",
        "question_count": 15,
        "duration_minutes": 45,
        "pass_mark": 75,
    },
]


@exam_bp.route('/questions', methods=['GET'])
def get_questions():
    return {"questions": SAMPLE_QUESTIONS}


@exam_bp.route('/dashboard', methods=['GET'])
def dashboard_data():
    return {"exams": SAMPLE_EXAMS}


@exam_bp.route('/review', methods=['POST'])
def review_data():
    payload = request.get_json(silent=True) or {}
    answers = payload.get("answers") or {}
    questions = payload.get("questions") or SAMPLE_QUESTIONS

    if not isinstance(answers, dict):
        return {"message": "answers must be an object"}, 400

    total = len(questions)
    answered = sum(1 for _, value in answers.items() if value)

    return {
        "answered": answered,
        "unanswered": max(total - answered, 0),
        "total": total,
        "message": "Review data generated",
    }


@exam_bp.route('/submit', methods=['POST'])
def submit():
    payload = request.get_json(silent=True) or {}
    answers = payload.get("answers") or {}

    if not isinstance(answers, dict):
        return {"message": "Invalid submission payload"}, 400

    answered_count = sum(1 for _, value in answers.items() if value)

    return {
        "message": "Submitted successfully",
        "answered_count": answered_count,
    }
