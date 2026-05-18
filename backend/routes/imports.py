import os
from pathlib import Path
import pandas as pd
from flask import Blueprint, request
from sqlalchemy import insert

from backend.config import engine
from backend.models import students

import_bp = Blueprint('import_bp', __name__)

BACKEND_DIR = Path(__file__).resolve().parent.parent
UPLOAD_FOLDER = BACKEND_DIR / 'uploads'

UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)


@import_bp.route('/import-students', methods=['POST'])
def import_students():
    if 'file' not in request.files:
        return {"error": "No file uploaded"}, 400

    file = request.files['file']

    if not file.filename:
        return {"error": "No file selected"}, 400

    filepath = UPLOAD_FOLDER / file.filename
    file.save(str(filepath))

    df = pd.read_csv(str(filepath))

    if not {'username', 'email'}.issubset(df.columns):
        msg = "CSV must contain username and email columns"
        return {"error": msg}, 400

    students_data = []

    with engine.begin() as connection:
        for _, row in df.iterrows():
            student = {
                "username": str(row['username']).strip(),
                "email": str(row['email']).strip(),
            }
            students_data.append(student)
            connection.execute(insert(students), [student])

    return {
        "message": "Students imported successfully",
        "students": students_data,
    }
