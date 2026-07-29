# secure-exam-usb-os
Secure bootable USB-based OS for controlled BYOD examinations.

## Project Summary
This repository contains the backend, frontend admin dashboard, database scripts, and OS-side configuration files for generating a secure exam ISO.

## Current Architecture
Frontend admin dashboard -> backend validation and config generation -> SQLite persistence -> OS config injection -> ISO build pipeline -> USB deployment -> student boot flow -> Moodle exam launch.

## Team Roles
- William: backend API, config generation, database-backed save/build flow
- Afua: frontend admin dashboard and bootable OS integration
- Wendy: database schema, exam profiles, build records, and supporting SQL

## Current Status
- Backend and database contract are aligned.
- Frontend dashboard can generate, save, and request a build.
- OS config loader is aligned with the backend-generated `system.json` shape.
- Real ISO building is still a stub in `OS/build/build-iso.sh`.
- Moodle-side exam content and live exam URL are still being prepared by the frontend/OS team.

## Useful Docs
- [Backend README](backend/README.md)
- [Team Handoff](TEAM_HANDOFF.md)
- [OS README](OS/README.md)

## Note
The project is now in integration-testing mode rather than setup mode. The remaining work is the actual ISO build implementation and final Moodle-driven exam test.
