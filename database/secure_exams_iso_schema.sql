PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS admins (
    admin_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Administrator'
        CHECK (role IN ('Super Admin', 'Administrator')),
    created_at DATETIME NOT NULL DEFAULT (datetime('now')),
    last_login DATETIME
);

CREATE TABLE IF NOT EXISTS templates (
    template_id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_name TEXT NOT NULL,
    description TEXT,
    version TEXT,
    created_at DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS security_profiles (
    profile_id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_name TEXT NOT NULL UNIQUE,
    kiosk_mode INTEGER NOT NULL DEFAULT 1 CHECK (kiosk_mode IN (0, 1)),
    usb_boot_support INTEGER NOT NULL DEFAULT 1 CHECK (usb_boot_support IN (0, 1)),
    browser_lock INTEGER NOT NULL DEFAULT 1 CHECK (browser_lock IN (0, 1)),
    url_restriction INTEGER NOT NULL DEFAULT 1 CHECK (url_restriction IN (0, 1)),
    auto_login INTEGER NOT NULL DEFAULT 0 CHECK (auto_login IN (0, 1)),
    disable_printing INTEGER NOT NULL DEFAULT 1 CHECK (disable_printing IN (0, 1)),
    screen_capture_block INTEGER NOT NULL DEFAULT 1 CHECK (screen_capture_block IN (0, 1)),
    created_at DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS exam_configurations (
    config_id INTEGER PRIMARY KEY AUTOINCREMENT,
    config_uuid TEXT NOT NULL UNIQUE,
    exam_name TEXT NOT NULL,
    exam_url TEXT,
    duration INTEGER,
    exam_source TEXT NOT NULL CHECK (exam_source IN ('MOODLE', 'LOCAL')),
    moodle_course_id INTEGER,
    template_id INTEGER,
    profile_id INTEGER,
    created_by INTEGER,
    config_json TEXT NOT NULL DEFAULT '{}',
    created_at DATETIME NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (template_id) REFERENCES templates (template_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (profile_id) REFERENCES security_profiles (profile_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES admins (admin_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS iso_builds (
    build_id INTEGER PRIMARY KEY AUTOINCREMENT,
    build_uuid TEXT NOT NULL UNIQUE,
    config_id INTEGER NOT NULL,
    admin_id INTEGER NOT NULL,
    iso_name TEXT,
    status TEXT NOT NULL DEFAULT 'Pending'
        CHECK (status IN ('Pending', 'Building', 'Completed', 'Failed')),
    iso_size TEXT,
    error_message TEXT,
    build_log TEXT,
    created_at DATETIME NOT NULL DEFAULT (datetime('now')),
    completed_at DATETIME,
    FOREIGN KEY (config_id) REFERENCES exam_configurations (config_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (admin_id) REFERENCES admins (admin_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS build_progress (
    progress_id INTEGER PRIMARY KEY AUTOINCREMENT,
    build_id INTEGER NOT NULL,
    stage TEXT,
    percentage INTEGER CHECK (percentage BETWEEN 0 AND 100),
    status TEXT,
    updated_at DATETIME NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (build_id) REFERENCES iso_builds (build_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS build_logs (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    build_id INTEGER NOT NULL,
    action TEXT,
    message TEXT,
    logged_at DATETIME NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (build_id) REFERENCES iso_builds (build_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_exam_configurations_template
    ON exam_configurations (template_id);
CREATE INDEX IF NOT EXISTS idx_exam_configurations_profile
    ON exam_configurations (profile_id);
CREATE INDEX IF NOT EXISTS idx_exam_configurations_created_by
    ON exam_configurations (created_by);
CREATE INDEX IF NOT EXISTS idx_iso_builds_config
    ON iso_builds (config_id);
CREATE INDEX IF NOT EXISTS idx_iso_builds_admin
    ON iso_builds (admin_id);
CREATE INDEX IF NOT EXISTS idx_build_progress_build
    ON build_progress (build_id);
CREATE INDEX IF NOT EXISTS idx_build_logs_build
    ON build_logs (build_id);
