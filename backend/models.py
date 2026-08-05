from sqlalchemy import Table, Column, Integer, String, Text, DateTime, ForeignKey, MetaData
from datetime import datetime


metadata = MetaData()


admins = Table(
    "admins", metadata,
    Column("admin_id", Integer, primary_key=True),
    Column("username", String, nullable=False, unique=True),
    Column("email", String, nullable=False, unique=True),
    Column("password_hash", String, nullable=False),
    Column("role", String, nullable=False, default="Administrator"),
    Column("created_at", DateTime, default=datetime.utcnow),
    Column("last_login", DateTime, nullable=True),
)

templates = Table(
    "templates", metadata,
    Column("template_id", Integer, primary_key=True),
    Column("template_name", String, nullable=False),
    Column("description", Text, default=""),
    Column("version", String, default=""),
    Column("created_at", DateTime, default=datetime.utcnow),
)

security_profiles = Table(
    "security_profiles", metadata,
    Column("profile_id", Integer, primary_key=True),
    Column("profile_name", String, nullable=False, unique=True),
    Column("kiosk_mode", Integer, default=1),
    Column("usb_boot_support", Integer, default=1),
    Column("browser_lock", Integer, default=1),
    Column("url_restriction", Integer, default=1),
    Column("auto_login", Integer, default=0),
    Column("disable_printing", Integer, default=1),
    Column("screen_capture_block", Integer, default=1),
    Column("created_at", DateTime, default=datetime.utcnow),
)

exam_configurations = Table(
    "exam_configurations", metadata,
    Column("config_id", Integer, primary_key=True),
    Column("config_uuid", String, unique=True, nullable=False),
    Column("exam_name", String, nullable=False),
    Column("exam_url", Text, default=""),
    Column("duration", Integer, default=120),
    Column("exam_source", String, default="MOODLE"),
    Column("moodle_course_id", Integer, nullable=True),
    Column("template_id", Integer, ForeignKey("templates.template_id"), nullable=True),
    Column("profile_id", Integer, ForeignKey("security_profiles.profile_id"), nullable=True),
    Column("created_by", Integer, ForeignKey("admins.admin_id"), nullable=True),
    Column("config_json", Text, default="{}"),
    Column("created_at", DateTime, default=datetime.utcnow),
)

iso_builds = Table(
    "iso_builds",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("config_id", String, nullable=False),
    Column("build_id", String, nullable=False),
    Column("status", String, default="Pending"),
    Column("iso_filename", String, default=""),
    Column("iso_size_bytes", Integer, default=0),
    Column("sha256_hash", String, default=""),
    Column("build_log", Text, default=""),
    Column("error_message", Text, default=""),
    Column("requested_by", String),
    Column("created_at", DateTime, default=datetime.utcnow),
    Column("completed_at", DateTime, nullable=True),
)

build_progress = Table(
    "build_progress", metadata,
    Column("progress_id", Integer, primary_key=True),
    Column("build_id", Integer, ForeignKey("iso_builds.build_id"), nullable=False),
    Column("stage", String, default=""),
    Column("percentage", Integer, default=0),
    Column("status", String, default=""),
    Column("updated_at", DateTime, default=datetime.utcnow),
)

build_logs = Table(
    "build_logs", metadata,
    Column("log_id", Integer, primary_key=True),
    Column("build_id", Integer, ForeignKey("iso_builds.build_id"), nullable=False),
    Column("action", String, default=""),
    Column("message", Text, default=""),
    Column("logged_at", DateTime, default=datetime.utcnow),
)

build_configuration_snapshots = Table(
    "build_configuration_snapshots", metadata,
    Column("snapshot_id", Integer, primary_key=True),
    Column("build_id", Integer, ForeignKey("iso_builds.build_id"), nullable=False, unique=True),
    Column("config_id", Integer, ForeignKey("exam_configurations.config_id"), nullable=False),
    Column("configuration_json", Text, nullable=False),
    Column("created_at", DateTime, default=datetime.utcnow),
)

iso_artifacts = Table(
    "iso_artifacts", metadata,
    Column("artifact_id", Integer, primary_key=True),
    Column("build_id", Integer, ForeignKey("iso_builds.build_id"), nullable=False, unique=True),
    Column("file_name", String, nullable=False),
    Column("file_path", Text, nullable=False),
    Column("file_size_bytes", Integer, default=0),
    Column("sha256_checksum", String, default=""),
    Column("download_url", Text, default=""),
    Column("created_at", DateTime, default=datetime.utcnow),
)

admin_audit_logs = Table(
    "admin_audit_logs", metadata,
    Column("audit_log_id", Integer, primary_key=True),
    Column("admin_id", Integer, ForeignKey("admins.admin_id"), nullable=True),
    Column("action", String, nullable=False),
    Column("entity_type", String, nullable=False),
    Column("entity_id", Integer, nullable=True),
    Column("description", Text, default=""),
    Column("created_at", DateTime, default=datetime.utcnow),
)

# ----- Legacy tables (for backward compatibility with student imports) -----
students = Table(
    "students", metadata,
    Column("id", Integer, primary_key=True),
    Column("username", String),
    Column("email", String),
)