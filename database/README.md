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
