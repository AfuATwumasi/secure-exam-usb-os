# Backend — KNUST Secure Exam OS

## Overview

This backend serves as the configuration management and ISO generation system for the KNUST Secure Examination Operating System (KSEOS). It provides a REST API for administrators to configure exam settings, generate `system.json` configuration files, and request custom bootable ISO images.

## Architecture

```
Frontend (Admin Dashboard)
        │
        ▼
   Backend API  ←── You are here
        │
        ├──► Config Generator  →  system.json
        │
        ├──► Database (SQLite) →  exam_configs, iso_builds
        │
        └──► ISO Builder (stub)→  Custom bootable ISO
                                     │
                                     ▼
                                USB Deployment
```

## Who Does What

| Team Member | Role |
|-------------|------|
| **You (William)** | Backend — config generation, API, ISO build orchestration |
| **Team Leader** | OS template (Xubuntu ISO), startup scripts, browser launcher |
| **Database Teammate** | Database schema design, exam profiles, security settings, ISO build records |
| **Frontend (to be assigned)** | Admin dashboard UI |

## Files Added / Modified

### New Files

| File | Purpose |
|------|---------|
| `config_generator.py` | Generates `system.json` exactly matching the OS schema. Includes validation, security profile presets (strict/moderate), auto domain extraction from exam URLs. |
| `iso_builder.py` | ISO Builder Service stub. Ready for implementation when the master ISO is available on a Linux server with `xorriso` and `squashfs-tools`. |
| `routes/config_routes.py` | 8 API endpoints for exam configuration management and ISO build requests. |

### Modified Files

| File | Changes |
|------|---------|
| `models.py` | Added `exam_configs` table (stores exam configurations) and `iso_builds` table (tracks ISO build requests and status). |
| `app.py` | Registered the new `config_bp` blueprint. |
| `requirements.txt` | No changes needed — existing dependencies work. |

## API Reference

All config endpoints are prefixed with `/api/config`.

### 1. Generate Configuration

Generate a `system.json` from administrator input.

```
POST /api/config/generate
```

**Request Body:**
```json
{
  "exam_url": "https://moodle.knust.edu.gh/mod/quiz/view.php?id=12345",
  "exam_name": "CSC401 Final Examination",
  "exam_duration": 120,
  "course_code": "CSC401",
  "institution": "Kwame Nkrumah University of Science and Technology",
  "trusted_ssids": ["KNUST_EXAM"],
  "profile": "strict",
  "disable_terminal": true,
  "disable_usb": true,
  "disable_printing": true,
  "disable_screenshots": true,
  "kiosk_mode": true,
  "allow_ethernet": true,
  "exam_server": "moodle.knust.edu.gh"
}
```

**Response (200):**
```json
{
  "message": "Configuration generated successfully",
  "config": { ... },
  "config_json": "{ ... }"
}
```

### 2. Save Configuration

Persist a generated configuration to the database.

```
POST /api/config/save
```

**Request Body:**
```json
{
  "config": { ... },
  "name": "CSC401 Final - Strict Profile",
  "description": "Strict lockdown for practical exam",
  "course_code": "CSC401",
  "created_by": "admin"
}
```

**Response (201):**
```json
{
  "message": "Configuration saved successfully",
  "config_id": "cfg-20260722140530-a1b2c3d4",
  "config_json": "{ ... }"
}
```

### 3. Get Configuration

Retrieve a saved configuration by its ID.

```
GET /api/config/<config_id>
```

### 4. List Configurations

List all saved configurations.

```
GET /api/config/
```

### 5. Delete Configuration

```
DELETE /api/config/<config_id>
```

### 6. Request ISO Build

Request an ISO build for a saved configuration.

```
POST /api/config/<config_id>/build
```

### 7. Get Build Status

Check the status of an ISO build.

```
GET /api/config/builds/<build_id>
```

### 8. List Builds

List all ISO build requests.

```
GET /api/config/builds
```

## Config Generator (`config_generator.py`)

This module is the bridge between the backend and the OS. It generates `system.json` exactly as the OS expects it at `/etc/exam-kiosk/system.json`.

### Key Functions

| Function | Purpose |
|----------|---------|
| `generate_config()` | Main entry point — produces a complete config dict from simplified parameters |
| `profile_strict()` | Preset: locks down everything (terminal, USB, printing, screenshots) |
| `profile_moderate()` | Preset: terminal locked, USB and printing allowed |
| `validate_config()` | Validates config against the OS schema before returning |
| `config_to_json()` | Serializes config to a pretty-printed JSON string |

### What the Generated `system.json` Looks Like

The output matches the schema in `OS/config/system.example.json` with sections for:
- **exam** — name, URL, institution, allowed domains
- **browser** — kiosk mode, restart on close, delays, disabled features
- **system** — hostname, live username, build version
- **network** — trusted SSIDs, verification settings, domain filtering, port rules
- **security** — desktop, keyboard, devices, session, browser restrictions
- **branding** — product names, wallpapers, display settings
- **administrator** — admin username, recovery options
- **student** — exam user, autologin

## ISO Builder (`iso_builder.py`)

**Status: 🚧 Stub — Not Yet Functional**

This module will handle the automated ISO build process. It requires:
- The **master ISO template** placed in `storage/master-isos/`
- A Linux server with:
  - `xorriso` — for ISO manipulation
  - `squashfs-tools` (`mksquashfs`, `unsquashfs`) — for filesystem extraction/rebuild
  - `genisoimage` — for ISO generation

### Build Process (When Implemented)

```
1. Validate master ISO exists
2. Extract SquashFS from ISO
3. Write system.json → /etc/exam-kiosk/system.json
4. Replace branding assets (optional)
5. Rebuild SquashFS
6. Generate new ISO with xorriso
7. Calculate SHA-256 checksum
8. Store output in storage/generated-isos/
9. Record build metadata in database
```

## Database Models

### `exam_configs` Table

Stores saved exam configurations.

| Column | Type | Description |
|--------|------|-------------|
| `config_id` | String (unique) | Auto-generated ID (e.g. `cfg-20260722-a1b2c3d4`) |
| `name` | String | Friendly name for the config |
| `exam_url` | String | The Moodle/examination URL |
| `profile` | String | Security profile: strict, moderate, or custom |
| `config_json` | Text | Full system.json content |
| `created_by` | String | Admin who created it |

### `iso_builds` Table

Tracks ISO build requests.

| Column | Type | Description |
|--------|------|-------------|
| `build_id` | String (unique) | Auto-generated ID (e.g. `build-20260722-...`) |
| `config_id` | String | Reference to the exam_config used |
| `status` | String | pending, building, completed, failed |
| `iso_filename` | String | Generated ISO filename |
| `sha256_hash` | String | ISO checksum for verification |
| `build_log` | Text | Build process logs |
| `error_message` | Text | Error details if build failed |

## Running the Backend

```bash
# Install dependencies
pip install -r backend/requirements.txt

# Run the server
python backend/app.py

# Server starts at http://localhost:5000
```

No database setup needed — SQLite is automatically created as `backend/exam.db`.

## Technical Contract with the OS

The interface between the backend and the OS is:

**Backend produces:**
- `/etc/exam-kiosk/system.json` — configuration file
- Optional branding assets (wallpaper, logo)

**OS consumes:**
- `system.json` at boot via `config-loader.sh`
- Exports config as environment variables for startup scripts
- Launches browser in kiosk mode with the exam URL

**Backend does NOT:**
- Modify Linux shell scripts
- Modify startup logic
- Modify the kernel
- Modify desktop configuration outside approved branding assets

## Next Steps

1. **When master ISO is ready:** Implement `iso_builder.py`'s `build_iso()` function
2. **When frontend is ready:** Connect the admin dashboard to these API endpoints
3. **Future:** Add more security profiles, webcam policies, Bluetooth restrictions
</｜｜DSML｜｜>
</write_to_file>