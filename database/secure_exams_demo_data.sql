PRAGMA foreign_keys = ON;

INSERT INTO admins (username, email, password_hash, role)
SELECT 'demo_admin', 'demo.admin@secureexams.local', 'REPLACE_WITH_A_REAL_PASSWORD_HASH', 'Super Admin'
WHERE NOT EXISTS (SELECT 1 FROM admins WHERE username = 'demo_admin');

INSERT INTO templates (template_name, description, version)
SELECT 'Secure Ubuntu Exam Template', 'Base image for locked-down examination machines.', '1.0'
WHERE NOT EXISTS (
    SELECT 1 FROM templates
    WHERE template_name = 'Secure Ubuntu Exam Template' AND version = '1.0'
);

INSERT INTO security_profiles (
    profile_name, kiosk_mode, usb_boot_support, browser_lock,
    url_restriction, auto_login, disable_printing, screen_capture_block
)
SELECT 'Standard Examination Lockdown', 1, 1, 1, 1, 0, 1, 1
WHERE NOT EXISTS (
    SELECT 1 FROM security_profiles
    WHERE profile_name = 'Standard Examination Lockdown'
);

INSERT INTO exam_configurations (
    config_uuid, exam_name, exam_url, duration, exam_source, moodle_course_id,
    template_id, profile_id, created_by, config_json
)
SELECT
    'cfg-demo-database-systems-final',
    'Database Systems Final Examination',
    'https://exam.example.edu/database-systems-final',
    120,
    'MOODLE',
    101,
    (SELECT template_id FROM templates
     WHERE template_name = 'Secure Ubuntu Exam Template' AND version = '1.0'
     ORDER BY template_id DESC LIMIT 1),
    (SELECT profile_id FROM security_profiles
     WHERE profile_name = 'Standard Examination Lockdown'),
    (SELECT admin_id FROM admins WHERE username = 'demo_admin'),
    '{"exam":{"name":"Database Systems Final Examination","url":"https://exam.example.edu/database-systems-final"}}'
WHERE NOT EXISTS (
    SELECT 1 FROM exam_configurations
    WHERE exam_name = 'Database Systems Final Examination'
);

INSERT INTO iso_builds (build_uuid, config_id, admin_id, iso_name, status, iso_size, completed_at)
SELECT
    'build-demo-database-systems-final',
    (SELECT config_id FROM exam_configurations
     WHERE exam_name = 'Database Systems Final Examination'
     ORDER BY config_id DESC LIMIT 1),
    (SELECT admin_id FROM admins WHERE username = 'demo_admin'),
    'database-systems-final-v1.iso',
    'Completed',
    '2.1 GB',
    datetime('now')
WHERE NOT EXISTS (
    SELECT 1 FROM iso_builds
    WHERE iso_name = 'database-systems-final-v1.iso'
);

INSERT INTO build_configuration_snapshots (build_id, config_id, configuration_json)
SELECT
    b.build_id,
    b.config_id,
    '{"exam_name":"Database Systems Final Examination","duration_minutes":120,"exam_source":"MOODLE","moodle_course_id":101,"template":"Secure Ubuntu Exam Template","security_profile":"Standard Examination Lockdown"}'
FROM iso_builds AS b
WHERE b.iso_name = 'database-systems-final-v1.iso'
  AND NOT EXISTS (
      SELECT 1 FROM build_configuration_snapshots AS s
      WHERE s.build_id = b.build_id
  );

INSERT INTO build_progress (build_id, stage, percentage, status)
SELECT build_id, 'Preparing template', 25, 'Completed'
FROM iso_builds
WHERE iso_name = 'database-systems-final-v1.iso'
  AND NOT EXISTS (
      SELECT 1 FROM build_progress
      WHERE build_id = iso_builds.build_id AND stage = 'Preparing template'
  );

INSERT INTO build_progress (build_id, stage, percentage, status)
SELECT build_id, 'Applying security profile', 60, 'Completed'
FROM iso_builds
WHERE iso_name = 'database-systems-final-v1.iso'
  AND NOT EXISTS (
      SELECT 1 FROM build_progress
      WHERE build_id = iso_builds.build_id AND stage = 'Applying security profile'
  );

INSERT INTO build_progress (build_id, stage, percentage, status)
SELECT build_id, 'Creating ISO artifact', 100, 'Completed'
FROM iso_builds
WHERE iso_name = 'database-systems-final-v1.iso'
  AND NOT EXISTS (
      SELECT 1 FROM build_progress
      WHERE build_id = iso_builds.build_id AND stage = 'Creating ISO artifact'
  );

INSERT INTO build_logs (build_id, action, message)
SELECT build_id, 'BUILD_COMPLETED', 'ISO build completed successfully.'
FROM iso_builds
WHERE iso_name = 'database-systems-final-v1.iso'
  AND NOT EXISTS (
      SELECT 1 FROM build_logs
      WHERE build_id = iso_builds.build_id AND action = 'BUILD_COMPLETED'
  );

INSERT INTO iso_artifacts (build_id, file_name, file_path, file_size_bytes, sha256_checksum, download_url)
SELECT
    build_id,
    'database-systems-final-v1.iso',
    '/srv/secure-exams/isos/database-systems-final-v1.iso',
    2254857830,
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    '/downloads/database-systems-final-v1.iso'
FROM iso_builds
WHERE iso_name = 'database-systems-final-v1.iso'
  AND NOT EXISTS (
      SELECT 1 FROM iso_artifacts
      WHERE build_id = iso_builds.build_id
  );

INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, description)
SELECT
    (SELECT admin_id FROM admins WHERE username = 'demo_admin'),
    'ISO_BUILD_COMPLETED',
    'iso_builds',
    build_id,
    'Created the demonstration Database Systems examination ISO.'
FROM iso_builds
WHERE iso_name = 'database-systems-final-v1.iso'
  AND NOT EXISTS (
      SELECT 1 FROM admin_audit_logs
      WHERE entity_type = 'iso_builds'
        AND entity_id = iso_builds.build_id
        AND action = 'ISO_BUILD_COMPLETED'
  );
