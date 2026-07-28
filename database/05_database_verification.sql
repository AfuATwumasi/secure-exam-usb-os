-- 1. Confirm the seven core and three supporting application tables exist.
SELECT name AS table_name
FROM sqlite_master
WHERE type = 'table'
  AND name NOT LIKE 'sqlite_%'
ORDER BY name;

-- 2. Confirm foreign-key definitions are valid. A correct database returns no rows.
PRAGMA foreign_key_check;

-- 3. Display each generated ISO build and the configuration used for it.
SELECT
    build_id,
    iso_name,
    exam_name,
    template_name,
    profile_name,
    requested_by,
    build_status,
    latest_progress_percentage,
    latest_stage,
    download_url
FROM v_iso_build_dashboard
ORDER BY build_created_at DESC;

-- 4. Display the progress history for each ISO build.
SELECT
    b.iso_name,
    p.stage,
    p.percentage,
    p.status,
    p.updated_at
FROM build_progress AS p
JOIN iso_builds AS b ON b.build_id = p.build_id
ORDER BY b.build_id, p.progress_id;

-- 5. Display the log history for each ISO build.
SELECT
    iso_name,
    exam_name,
    action,
    message,
    logged_at
FROM v_build_log_history
ORDER BY logged_at DESC;

-- 6. Display administrator audit activity.
SELECT
    username,
    role,
    action,
    entity_type,
    entity_id,
    description,
    created_at
FROM v_admin_activity
ORDER BY created_at DESC;
