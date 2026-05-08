import os
import pandas as pd
from flask import Blueprint, request
from sqlalchemy import insert

from config import engine
from models import metadata, students

import_bp = Blueprint('import_bp', __name__)

UPLOAD_FOLDER = 'uploads'

os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@import_bp.route('/import-students', methods=['POST'])
def import_students():
    if 'file' not in request.files:
        return {"error": "No file uploaded"}, 400

    file = request.files['file']

    if not file.filename:
        return {"error": "No file selected"}, 400

    filepath = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(filepath)

    df = pd.read_csv(filepath)

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
