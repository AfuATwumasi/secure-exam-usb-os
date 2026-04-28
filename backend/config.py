import os


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "change-me")
    DATABASE_URI = os.getenv("DATABASE_URI", "sqlite:///exam.db")
