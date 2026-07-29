# Secure Exams Database

## Run order

Run these scripts in order against a SQLite database:

1. `secure_exams_iso_schema.sql`
2. `secure_exams_phase2.sql`
3. `secure_exams_demo_data.sql` (optional sample data)
4. `04_database_views.sql`
5. `05_database_verification.sql`

## Verification

Run `05_database_verification.sql`.

A correct setup returns 10 application tables and no rows from
`PRAGMA foreign_key_check`.
PRAGMA foreign_keys = ON;
```

## Main workflow

1. An administrator creates an exam configuration using a template and security profile.
2. The application creates a `Pending` record in `iso_builds`.
3. The ISO-generation worker updates `build_progress` and adds entries to `build_logs`.
4. When the build succeeds, the worker updates the build to `Completed` and creates an `iso_artifacts` record.
5. The dashboard reads `v_iso_build_dashboard` to show build status and download details.

## Verification

Run:

```sql
PRAGMA foreign_key_check;
```

No returned rows means the foreign-key relationships are valid. The verification script should show ten application tables.

## Security notes

- Store password hashes only; never store plain-text passwords.
- Do not commit `.db` files, passwords, API keys, or environment variables.
- Restrict ISO downloads to authorized administrators.
