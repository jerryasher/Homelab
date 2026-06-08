# App 2 - Windows Development Workstation Architecture

## Purpose

This document describes the architecture, standards, and operating procedures implemented in my Windows systems (development or server)

The goals are:

-   Keep important files separate from operating system state.
    
-   Use short, memorable, and consistent paths.
    
-   Make workstation rebuilds straightforward and repeatable.
    
-   Use cloud storage and source control to protect important data.
    
-   Minimize dependence on Windows default locations where practical.
    
-   Standardize layouts across all systems.
    
-   Support future automation using PowerShell, Git, Scoop, and Ansible.
    

This document is intended primarily as a design reference and memory aid.

----------

# Design Principles

## Data Is More Important Than Software

Personal files, source code, scripts, and configuration should be protected.

Applications should generally be treated as replaceable.

----------

## Use Predictable Paths

Important files should live under:

```text
C:\me

```

This provides short, memorable, machine-independent paths.

----------

## Standardize Across Machines

Every workstation should use the same directory structure whenever practical.

A script written on one machine should work on another with minimal modification.

----------

## Prefer Reproducibility

Software installations should be reproducible.

Configuration should be stored in source control whenever practical.

----------

## Accept Windows

The architecture does not attempt to eliminate:

```text
C:\Users\<username>
AppData
LocalAppData
ProgramData

```

Windows and many applications depend on these locations.

Instead, the goal is to minimize the amount of important information stored there.

----------

## Prefer Native Solutions

Use standard Windows mechanisms when available.

Avoid unnecessary launcher scripts, redirection layers, and filesystem tricks.

Environment variables are preferred over custom wrappers when customization is required.

----------

# Filesystem Architecture

## Root Layout

```text
C:\me
│
├── bin
├── jerry
├── scoop
├── scoopglobalapps
├── scripts
└── workspace

```

----------

## Directory Purposes

### C:\me\jerry

Personal files.

Primary cloud-backed storage location.

Examples:

```text
Documents
Downloads
Pictures
Desktop
Notes
Archives

```

----------

### C:\me\workspace

Development projects and working repositories.

Generally protected through Git hosting rather than OneDrive.

----------

### C:\me\scripts

PowerShell scripts, automation, bootstrap code, and machine configuration.

Protected through Git.

----------

### C:\me\bin

Manually managed infrastructure software.

Examples:

```text
WinPython
Portable Utilities

```

----------

### C:\me\scoop

User-level Scoop applications.

----------

### C:\me\scoopglobalapps

Machine-wide Scoop applications.

----------

# Data Classification

## Class 1: Personal Data

Location:

```text
C:\me\jerry

```

Protection:

```text
OneDrive

```

Loss of this data is unacceptable.

----------

## Class 2: Source Code and Projects

Location:

```text
C:\me\workspace

```

Protection:

```text
Git
GitHub
Other Git Remotes

```

Local copies may be recreated from source control.

----------

## Class 3: Configuration and Automation

Location:

```text
C:\me\scripts

```

Protection:

```text
Git

```

Machine rebuild procedures should depend heavily on this content.

----------

## Class 4: Applications

Locations:

```text
C:\me\scoop
C:\me\scoopglobalapps

```

Applications should generally be recreated rather than backed up.

----------

## Class 5: Operating System State

Locations:

```text
C:\Windows
C:\Users
C:\ProgramData
AppData

```

Treat as operating-system-managed.

Avoid storing important information here whenever practical.

----------

# Standard Locations

The following locations should exist on every development machine:

```text
C:\me\bin
C:\me\jerry
C:\me\scripts
C:\me\workspace

```

These form the core workstation contract.

----------

# Software Management Strategy

Preferred installation order:

1.  Scoop
    
2.  Portable software
    
3.  Vendor installer
    

Rationale:

-   Reproducibility
    
-   Easier upgrades
    
-   Easier inventory
    
-   Cleaner removal
    

Not all software belongs in Scoop.

Infrastructure software may require separate installation procedures.

----------

# Python Strategy

## Stable Python

Install WinPython to be used as the system's stable known-good Python.

Suggested location:

```text
C:\me\bin\WinPython

```

This installation should remain stable and available to other tools.

----------

## Project Python

Projects should use virtual environments with Python versions managed using standard PEP friendly tooling

Example:

```powershell
python -m venv .venv

```

Project-specific experimentation should occur inside virtual environments rather than the stable WinPython installation.

----------

# Backup Strategy

## OneDrive

Primary protection for:

```text
C:\me\jerry

```

The goal is for personal files to exist in a single authoritative location.

Avoid duplicate Documents, Downloads, or Pictures folders whenever possible.

----------

## Git

Primary protection for:

```text
C:\me\workspace
C:\me\scripts

```

Repositories should be pushed regularly.

----------

# Configuration Ownership

The intended ownership model is:

```text
Personal Files        -> OneDrive
Projects             -> Git
Automation Scripts   -> Git
SSH Keys             -> Backup + Cloud Storage
Emacs Configuration  -> Git
Git Configuration    -> Git
Applications         -> Recreated
Windows State        -> Recreated

```

----------

# Non-Goals

This architecture does not attempt to:

-   Eliminate AppData.
    
-   Eliminate C:\Users.
    
-   Make every application portable.
    
-   Relocate all Windows configuration.
    
-   Replace Windows administration entirely.
    

The goal is simply to make important files easy to find, easy to protect, and easy to restore.

----------

# Rebuild Test

A useful validation question is:

"If this SSD failed today, what would I lose?"

The desired answer is:

```text
Very little.

```

Most important files should already exist in OneDrive, Git repositories, backups, or a combination of those systems.

# Software Categories

## Category 1: Scoop-Managed Applications

These applications should normally be installed through Scoop. Many of these applications are context depending, depending on the role of the development system or server

Examples:

```text
Chrome
Brave
Firefox
VS Code
Cursor
GitHub Desktop
Git
GNU Emacs
WinMerge
VLC
qBittorrent
SumatraPDF
PowerToys
WizTree
Rufus
Ollama
Tailscale
```

Benefits:

* centralized updates
* reproducible rebuilds
* clean uninstall
* easy inventory

Typical workflow:

```powershell
scoop install firefox
scoop install git
scoop install emacs
```

---

## Category 2: Infrastructure Software

These are foundational components and should not be treated as disposable applications.

Examples:

```text
WinPython
Docker Desktop
hardware drivers
GPU drivers
```

These should be installed and managed separately.

---

## Category 3: Vendor-Managed Software

Applications that frequently install drivers, services, or deep operating system integrations.

Examples:

```text
Windscribe
MiniTool Partition Wizard
vendor hardware utilities
```

These are usually best installed directly from the vendor.

---

## Category 4: Docker, Docker-desktop and WSL

See the Appendix documents App 1.A - Ansible under the topic WSL for Ansible Control and also App 2.F - Docker, Docker-desktop and WSL

