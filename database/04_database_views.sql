-- Read-only dashboard data for every ISO build.
CREATE VIEW IF NOT EXISTS v_iso_build_dashboard AS
SELECT
    b.build_id,
    b.iso_name,
    b.status AS build_status,
    b.iso_size,
    b.created_at AS build_created_at,
    b.completed_at,
    c.config_id,
    c.exam_name,
    c.exam_url,
    c.duration AS duration_minutes,
    c.exam_source,
    t.template_name,
    sp.profile_name,
    ad.username AS requested_by,
    ia.file_name,
    ia.file_path,
    ia.file_size_bytes,
    ia.sha256_checksum,
    ia.download_url,
    COALESCE((
        SELECT bp.percentage
        FROM build_progress AS bp
        WHERE bp.build_id = b.build_id
        ORDER BY bp.progress_id DESC
        LIMIT 1
    ), 0) AS latest_progress_percentage,
    (
        SELECT bp.stage
        FROM build_progress AS bp
        WHERE bp.build_id = b.build_id
        ORDER BY bp.progress_id DESC
        LIMIT 1
    ) AS latest_stage
FROM iso_builds AS b
JOIN exam_configurations AS c ON c.config_id = b.config_id
LEFT JOIN templates AS t ON t.template_id = c.template_id
LEFT JOIN security_profiles AS sp ON sp.profile_id = c.profile_id
JOIN admins AS ad ON ad.admin_id = b.admin_id
LEFT JOIN iso_artifacts AS ia ON ia.build_id = b.build_id;

-- Build log entries with their related ISO and examination name.
CREATE VIEW IF NOT EXISTS v_build_log_history AS
SELECT
    bl.log_id,
    bl.build_id,
    b.iso_name,
    c.exam_name,
    bl.action,
    bl.message,
    bl.logged_at
FROM build_logs AS bl
JOIN iso_builds AS b ON b.build_id = bl.build_id
JOIN exam_configurations AS c ON c.config_id = b.config_id;

-- Administrator actions for auditing screens.
CREATE VIEW IF NOT EXISTS v_admin_activity AS
SELECT
    al.audit_log_id,
    ad.username,
    ad.role,
    al.action,
    al.entity_type,
    al.entity_id,
    al.description,
    al.created_at
FROM admin_audit_logs AS al
LEFT JOIN admins AS ad ON ad.admin_id = al.admin_id;
