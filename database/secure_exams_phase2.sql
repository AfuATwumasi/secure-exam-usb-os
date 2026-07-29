PRAGMA foreign_keys = ON;

-- One immutable copy of the configuration used for each ISO build.
CREATE TABLE IF NOT EXISTS build_configuration_snapshots (
    snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
    build_id INTEGER NOT NULL UNIQUE,
    config_id INTEGER NOT NULL,
    configuration_json TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (build_id) REFERENCES iso_builds(build_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (config_id) REFERENCES exam_configurations(config_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- The generated ISO file produced by a successful build.
CREATE TABLE IF NOT EXISTS iso_artifacts (
    artifact_id INTEGER PRIMARY KEY AUTOINCREMENT,
    build_id INTEGER NOT NULL UNIQUE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size_bytes INTEGER CHECK (file_size_bytes >= 0),
    sha256_checksum TEXT,
    download_url TEXT,
    created_at DATETIME NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (build_id) REFERENCES iso_builds(build_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Records administrator actions that affect configurations and ISO builds.
CREATE TABLE IF NOT EXISTS admin_audit_logs (
    audit_log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    admin_id INTEGER,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id INTEGER,
    description TEXT,
    created_at DATETIME NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (admin_id) REFERENCES admins(admin_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_snapshots_config
    ON build_configuration_snapshots(config_id);
CREATE INDEX IF NOT EXISTS idx_audit_admin_created
    ON admin_audit_logs(admin_id, created_at);
