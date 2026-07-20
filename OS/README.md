# KNUST Secure Examination USB Operating System

## Overview

The KNUST Secure Examination USB Operating System is a customized Linux-based examination environment developed as part of a final year project at Kwame Nkrumah University of Science and Technology (KNUST).

The objective of the project is to provide students with a secure bootable operating system that launches directly into a controlled examination environment, preventing access to unauthorized resources while allowing access only to approved online examination platforms.

The operating system is built on **Xubuntu 24.04.4 LTS** using **Cubic (Custom Ubuntu ISO Creator)**.

---

# Project Architecture

```
                    Administrator Dashboard
                              │
                              ▼
                    Backend Management System
                              │
                              ▼
                Generates system.json Configuration
                              │
                              ▼
                  Injects Configuration into ISO
                              │
                              ▼
                     Generates Custom ISO Image
                              │
                              ▼
                   USB Flash Drive Distribution
                              │
                              ▼
               Student Boots Into Secure Exam OS
                              │
                              ▼
              Chromium/Firefox Opens Exam Platform
```

---

# Operating System Information

| Component | Value |
|-----------|-------|
| Base Distribution | Xubuntu 24.04.4 LTS |
| Desktop Environment | XFCE |
| Display Manager | LightDM |
| ISO Builder | Cubic |
| Browser | Firefox (Kiosk Mode) |
| Configuration Format | JSON |

---

# Repository Structure

```
OS/
│
├── config/
│   └── system.example.json
│
├── scripts/
│   ├── start-exam.sh
│   ├── exam-engine.sh
│   ├── config-loader.sh
│   ├── lockdown.sh
│   ├── network-check.sh
│   ├── network-assistant.sh
│   ├── system-hardening.sh
│   ├── validate-config.sh
│   ├── build-firefox-policy.sh
│   ├── admin-control.sh
│   ├── generate-diagnostics.sh
│   └── show-config.sh
│

```

---

# Current Features Implemented

## Automatic Login

The operating system automatically logs into the examination account.

---

## Secure Browser Launch

After login, the startup scripts automatically launch the examination browser in kiosk mode.

Features include:

- Full screen mode
- No browser menus
- No downloads
- No password saving
- No private browsing
- Automatic restart if browser closes

---

## System Lockdown

The operating system disables:

- Terminal access
- File Manager
- System Settings
- Task Manager
- Desktop icons
- Right-click menu
- Alt + Tab
- Ctrl + Alt + T
- Super (Windows) key
- Workspace switching
- Virtual terminals

---

## Session Protection

The operating system prevents users from:

- Logging out
- Shutting down
- Suspending
- Locking the screen

---

## Network Verification

Before launching the examination browser the OS verifies:

- Internet connectivity
- Trusted network (optional)
- Examination server availability (optional)

---

## Branding

The operating system includes custom KNUST branding.

Current branding includes:

- Custom wallpaper
- Custom login logo
- Product name
- Build version

---

# Configuration System

The operating system is completely configuration-driven.

All configurable values are stored inside:

```

/etc/exam-kiosk/system.json

```

This file is loaded during startup by:

```

config-loader.sh

```

The backend only needs to modify this JSON file when generating a new examination ISO.

---

# Startup Flow

```
BIOS
 │
 ▼
GRUB
 │
 ▼
Linux Kernel
 │
 ▼
Systemd
 │
 ▼
LightDM
 │
 ▼
Automatic Login
 │
 ▼
start-exam.sh
 │
 ▼
exam-engine.sh
 │
 ▼
config-loader.sh
 │
 ▼
validate-config.sh
 │
 ▼
network-check.sh
 │
 ▼
system-hardening.sh
 │
 ▼
Firefox Kiosk
 │
 ▼
Exam Platform
```

---

# Configuration Categories

The system.json file currently supports:

## Exam

- Exam name
- Examination URL
- Allowed domains

## Browser

- Kiosk mode
- Startup delay
- Restart if closed
- Disable downloads
- Disable printing
- Disable updates

## System

- Hostname
- Build version
- Autologin

## Network

- Trusted WiFi
- Ethernet support
- Internet verification
- Domain filtering
- Allowed ports

## Security

Desktop restrictions

Keyboard shortcuts

Browser restrictions

Device restrictions

Session restrictions

## Branding

Institution name

Wallpaper

Desktop branding

Product name

Build version

---

# Backend Integration

The backend **does not modify Linux scripts**.

Instead, it only generates a customized configuration.

Expected workflow:

```
Administrator
        │
        ▼
Backend Dashboard
        │
        ▼
Generate system.json
        │
        ▼
Inject into Master ISO
        │
        ▼
Generate ISO
        │
        ▼
Download ISO
        │
        ▼
Write ISO to USB
```

---

# Backend Responsibilities

The backend should generate:

- Examination URL
- Allowed domains
- Trusted networks
- Institution branding
- Build version
- Security profile

The backend should **not** modify:

- Shell scripts
- Linux services
- Startup scripts
- System binaries

---

# Security Philosophy

The operating system follows a layered security model.

1. Boot directly into examination environment.
2. Restrict desktop functionality.
3. Restrict browser functionality.
4. Validate network access.
5. Restrict system shortcuts.
6. Prevent session escape.
7. Launch only approved examination platform.

---

# Technologies Used

- Ubuntu/Xubuntu 24.04.4 LTS
- XFCE Desktop
- LightDM
- Cubic ISO Builder
- Bash Shell Scripting
- JSON Configuration
- Firefox
- Git
- GitHub

---

# Future Improvements

- Secure Boot support
- Exam server heartbeat monitoring
- Automatic updates
- Plymouth boot branding
- Encrypted configuration
- Offline examination mode
- Remote diagnostics
- Administrative dashboard integration

---

# Author

**Afua Britwum Twumasi**

Department of Computer Engineering

Kwame Nkrumah University of Science and Technology

Final Year Project

---

# Contributors

Frontend

Backend

Operating System Development

Documentation

Testing

---

# License

Academic Final Year Project

KNUST
