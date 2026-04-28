from sqlalchemy import create_engine


DATABASE_URL = "sqlite:///exam.db"

engine = create_engine(DATABASE_URL)
