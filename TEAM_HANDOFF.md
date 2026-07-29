# Team Handoff: Secure Exam USB OS

## What Is Working Now
- Backend login checks the admin table in SQLite.
- Backend config generation matches the OS `system.json` structure.
- Backend save/build endpoints write and read from the database.
- Frontend dashboard can authenticate, generate a config, save it, and request a build.
- OS `config-loader.sh` reads the backend-generated keys correctly.

## Ownership Split
- Backend: William
- Frontend + Bootable OS: Afua
- Database: Wendy

## Current Contracts
- Backend produces `system.json` and build metadata.
- Database stores admins, configs, builds, snapshots, and artifacts.
- OS consumes `/etc/exam-kiosk/system.json` at boot.
- Frontend submits exam URL, exam name, duration, security profile, and network settings.

## Still Pending
- `OS/build/build-iso.sh` is still a placeholder.
- Moodle test content / live exam URL is still in progress.
- A real end-to-end bootable ISO test has not been completed yet.

## Important Files
- [backend/routes/auth.py](backend/routes/auth.py)
- [backend/routes/config_routes.py](backend/routes/config_routes.py)
- [backend/config_generator.py](backend/config_generator.py)
- [OS/scripts/config-loader.sh](OS/scripts/config-loader.sh)
- [OS/config/system.example.json](OS/config/system.example.json)

## Suggested Next Step
Use the Moodle test URL once it is ready, then connect the ISO builder stub to the real build pipeline on the OS side.