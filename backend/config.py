from pathlib import Path
from sqlalchemy import create_engine

# Store the SQLite file inside the backend package to keep backend artifacts together
BASE_DIR = Path(__file__).resolve().parent
DATABASE_URL = f"sqlite:///{(BASE_DIR / 'exam.db').as_posix()}"

engine = create_engine(DATABASE_URL)
