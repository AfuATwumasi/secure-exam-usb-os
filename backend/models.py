from sqlalchemy import Table, Column, Integer, String, Text, DateTime, Boolean, JSON, MetaData
from datetime import datetime


metadata = MetaData()

# ----- Existing tables -----

users = Table(
    "users", metadata,
    Column("id", Integer, primary_key=True),
    Column("username", String),
    Column("password", String),
)

questions = Table(
    "questions", metadata,
    Column("id", Integer, primary_key=True),
    Column("question", String),
)

students = Table(
    "students", metadata,
    Column("id", Integer, primary_key=True),
    Column("username", String),
    Column("email", String),
)

# ----- New tables for exam configuration & ISO builds -----

exam_configs = Table(
    "exam_configs", metadata,
    Column("id", Integer, primary_key=True),
    Column("config_id", String, unique=True, nullable=False),
    Column("name", String, nullable=False),
    Column("description", String, default=""),
    Column("exam_url", String, nullable=False),
    Column("exam_duration", Integer, default=120),
    Column("course_code", String, default=""),
    Column("institution", String, default="Kwame Nkrumah University of Science and Technology"),
    Column("profile", String, default="strict"),
    Column("config_json", Text, nullable=False),
    Column("allowed_domains", Text, default="[]"),
    Column("trusted_ssids", Text, default="[]"),
    Column("disable_terminal", Boolean, default=True),
    Column("disable_usb", Boolean, default=False),
    Column("disable_printing", Boolean, default=True),
    Column("disable_screenshots", Boolean, default=True),
    Column("kiosk_mode", Boolean, default=True),
    Column("allow_ethernet", Boolean, default=True),
    Column("exam_server", String, default=""),
    Column("created_by", String, default="admin"),
    Column("created_at", DateTime, default=datetime.utcnow),
    Column("updated_at", DateTime, default=datetime.utcnow, onupdate=datetime.utcnow),
)

iso_builds = Table(
    "iso_builds", metadata,
    Column("id", Integer, primary_key=True),
    Column("config_id", String, nullable=False),
    Column("build_id", String, unique=True, nullable=False),
    Column("status", String, default="pending"),
    Column("iso_filename", String, default=""),
    Column("iso_size_bytes", Integer, default=0),
    Column("sha256_hash", String, default=""),
    Column("build_log", Text, default=""),
    Column("error_message", Text, default=""),
    Column("requested_by", String, default="admin"),
    Column("created_at", DateTime, default=datetime.utcnow),
    Column("completed_at", DateTime, nullable=True),
)
