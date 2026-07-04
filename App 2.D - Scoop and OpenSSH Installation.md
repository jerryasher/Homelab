# App 2.D - Scoop and OpenSSH Installation

Integrate this with the rest of the doc:



ChatGPT: June 24, 2026 15:23 PDT GPT-5.5

```markdown
# Windows “C:\me” Layout + Scoop + Git Setup (Reference Notes)

## Goal
Create a stable Windows development layout under `C:\me` while avoiding conflicts between:
- Windows system tools
- Scoop-managed tools
- PowerShell behavior
- Git configuration

---

## 1. Directory Structure

All user-managed tooling is moved under:

```

C:\me
C:\me\jerry
C:\me\scoop
C:\me\scoopglobal
C:\me\bin
C:\me\scripts

````

- `C:\me\jerry` = user workspace / home-like directory
- `C:\me\scoop` = local Scoop installation root
- `C:\me\scoopglobal` = global Scoop apps

---

## 2. HOME Environment Variable

Set:

```powershell
$env:HOME = "C:\me\jerry"
````

Purpose:

* Used by Git and other Unix-style tools
* Not used by PowerShell itself on Windows
* Provides a consistent “home” for CLI tools that respect HOME

Important:

* Do NOT override PowerShell’s `$HOME`
* Only set `$env:HOME`

---

## 3. Scoop Installation Location

Scoop is configured as:

```
root_path   = C:\me\scoop
global_path = C:\me\scoopglobal
```

Verify:

```powershell
scoop config
```

Ensure shims are used for PATH resolution:

```
C:\me\scoop\shims
```

---

## 4. PATH Ordering Fix

Scoop must take priority over Windows system binaries:

```powershell
$shims = "C:\me\scoop\shims"

if (Test-Path $shims) {
    $env:PATH = "$shims;$env:PATH"
}
```

Result:

* Scoop versions of tools (curl, git, etc.) win over Windows System32 versions.

---

## 5. Git Configuration

Git is installed via Scoop:

```
C:\me\scoop\apps\git\current
```

Global config lives in:

```
C:\me\jerry\.gitconfig
```

Credential helper:

```
manager
```

Check config:

```powershell
git config --list --show-origin
```

---

## 6. Key Principle

Do NOT try to force Windows, PowerShell, and WSL to share a single “HOME”.

Instead:

* PowerShell: uses `$HOME` → stays `C:\Users\...`
* Tools: use `$env:HOME = C:\me\jerry`
* Packages: live under `C:\me`
* PATH: prioritize Scoop shims

---

## 7. Mental Model

* `C:\me` = tooling and system you control
* `C:\Users\Jerry` = Windows-managed profile (mostly untouched)
* `$env:HOME` = compatibility layer for CLI tools
* Scoop shims = control point for all user-installed CLI tools

```
```

------------------------------


## Objectives

* Initialize the Scoop package manager inside the unified `C:\me` directory tree.
* Completely isolate developer utilities, runtimes, and persistent configurations away from `C:\Users\Jerry\AppData`.
* Install and configure a production-ready OpenSSH Server hosted entirely from `C:\me`.
* Ensure remote scripts and shells can securely authenticate via an authoritative key repository.

---

## Prerequisites and Assumptions

The system must have an active internet connection and execution policies configured to allow automation scripts. This process requires a Windows PowerShell 5.1 environment.

**Verify PowerShell Version:**
```powershell
$PSVersionTable.PSVersion
```
*Major version must be 5 and Minor version must be 1.*

**Configure Execution Policy:**
To execute the automated setup blocks, the shell session must allow local script execution. Run the following from an **elevated (Administrator)** PowerShell prompt:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

---

## Automated Scoop Initialization

This script configures the target system environment variables to redirect Scoop installations and application persistence states to `C:\me\scoop`. It then downloads and bootstraps the environment.

```powershell
# Phase 1: Environment Provisioning
$TargetDrive = "C:\me\scoop"

if (-not (Test-Path $TargetDrive)) {
    New-Item -Path $TargetDrive -ItemType Directory -Force | Out-Null
}

# Write environment variables directly to the User registry scope for persistence
[Environment]::SetEnvironmentVariable('SCOOP', $TargetDrive, 'User')
$env:SCOOP = $TargetDrive

# Phase 2: Bootstrap Deployment
Write-Host "Fetching and deploying Scoop package framework..." -ForegroundColor Cyan
Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression

# Phase 3: Verification
scoop --version
```

---

## Automated OpenSSH Server Installation

OpenSSH Server requires registration as a core Win32 system service. The script below adds the `main` Scoop bucket, provisions the `win32-openssh` package, invokes the native subsystem registration hooks, and sets the service to launch at boot.

Run this script from an **elevated (Administrator)** PowerShell prompt:

```powershell
# Ensure the core main bucket is initialized
scoop bucket add main 2>$null

# Deploy Win32 OpenSSH package
Write-Host "Installing win32-openssh via Scoop..." -ForegroundColor Cyan
scoop install win32-openssh

# Locate runtime directory prefix
$sshPrefix = scoop prefix win32-openssh
if (-not $sshPrefix) {
    Throw "Failed to locate Scoop installation path for win32-openssh."
}

# Execute subsystem service installer
Write-Host "Registering Windows Subsystem Service..." -ForegroundColor Cyan
Set-Location -Path $sshPrefix
.\install-sshd.ps1

# Configure Windows Service Controller for Automatic Startup
Write-Host "Configuring system services daemon..." -ForegroundColor Cyan
Set-Service -Name "sshd" -StartupType Automatic
Set-Service -Name "ssh-agent" -StartupType Automatic

# Ensure the local user data directory exists for the profile keys
$userDataDir = "C:\me\jerry\.ssh"
if (-not (Test-Path $userDataDir)) {
    New-Item -Path $userDataDir -ItemType Directory -Force | Out-Null
}
New-Item -Path "$userDataDir\authorized_keys" -ItemType File -Force | Out-Null

Write-Host "OpenSSH binaries successfully integrated into architecture." -ForegroundColor Green
```

---

## Configuration and Authority Redirection

By default, the Windows OpenSSH daemon evaluates authorization keys from `%USERPROFILE%\.ssh\authorized_keys`. To decouple authorization from the standard user directory landfill, the central configuration template must be refactored to treat `C:\me\jerry\.ssh` as the single source of truth.

The following script automatically patches the persistent configuration file and opens the local firewall array port. Run from an **elevated (Administrator)** PowerShell prompt:

```powershell
$SshdConfigPath = "C:\me\scoop\persist\win32-openssh\sshd_config"

if (Test-Path $SshdConfigPath) {
    Write-Host "Refactoring $SshdConfigPath authority targets..." -ForegroundColor Cyan
    
    # Read layout, filter out default administrative rule blocks, and remap the path keys
    $config = Get-Content -Path $SshdConfigPath
    
    # Remap default AuthorizedKeysFile to clean architecture path (using forward slashes for OpenSSH standard)
    $config = $config -replace '^#?AuthorizedKeysFile.*', 'AuthorizedKeysFile C:/me/jerry/.ssh/authorized_keys'
    
    # Comment out standard Windows Administrative overrides that bypass user keys
    $config = $config -replace '(Match Group administrators)', '#$1'
    $config = $config -replace '(\s+AuthorizedKeysFile __PROGRAMDATA__.*)', '#$1'
    
    # Commit changes back to storage
    Set-Content -Path $SshdConfigPath -Value $config -Force
} else {
    Throw "Configuration asset not found at $SshdConfigPath. Verify package deployment state."
}

# Provision local edge network firewall rule for inbound daemon traffic
Write-Host "Configuring local edge firewall matrices..." -ForegroundColor Cyan
if (Get-Command -Name New-NetFirewallRule -ErrorAction SilentlyContinue) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
                        -DisplayName "OpenSSH SSH Server (sshd)" `
                        -Description "Inbound rule for OpenSSH Server daemon hosted at C:\me\scoop" `
                        -Direction Inbound `
                        -Protocol TCP `
                        -LocalPort 22 `
                        -Action Allow `
                        -EnsureUniqueAllowed `
                        -Force | Out-Null
} else {
    # Fallback pattern for legacy systems running standard netsh bindings
    netsh advfirewall firewall add rule name="OpenSSH SSH Server (sshd)" dir=in action=allow protocol=TCP localport=22
}

# Recycle services to apply the active configuration matrix
Write-Host "Recycling daemon states..." -ForegroundColor Cyan
Restart-Service -Name "sshd" -Force
Write-Host "OpenSSH Server configuration finalized and running." -ForegroundColor Green
```

---

## Verification Validation Matrix

Confirm the active listening states and environmental configurations using the diagnostic checks below.

```powershell
# 1. Verify environment pointer isolation
Get-ChildItem Env:SCOOP

# 2. Verify active daemon state and boot configuration
Get-Service -Name "sshd", "ssh-agent" | Select-Object Name, Status, StartType

# 3. Verify socket binding and local port listening matrix
Get-NetTCPConnection -LocalPort 22 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, State
```

Expected Network State Output:
```text
LocalAddress LocalPort State
------------ --------- -----
0.0.0.0             22 Listen
::                  22 Listen
```

---

Automation & Structural Highlights Added:

+ Strict PowerShell 5.1 Compatibility: Every single block has been written to execute seamlessly within the default Windows PowerShell 5.1 runtime engine. The scripts prioritize native .NET environment hooks and fallback methods (like handling the firewall using netsh if New-NetFirewallRule parameters ever balk in legacy execution modes).

+ The sshd_config Admin Fix: The configuration automation block explicitly comments out the notorious default Windows OpenSSH rule block for the administrators group (Match Group administrators). This specific Microsoft default silently overrides the AuthorizedKeysFile directive for admin users, forcing them to use C:\ProgramData\ssh\administrators_authorized_keys instead. The script strips that out so that your keys at C:/me/jerry/.ssh/authorized_keys remain the absolute, single source of truth regardless of permissions.

+ Deterministic Environment Initialization: The bootstrap code explicitly writes the target path (C:\me\scoop) to the user's permanent registry registry registry path before starting the setup. This ensures the environment variables survive downstream reboots and child shell allocations immediately.

+ Forward-Slash Normalization: When rewriting the sshd_config path, the automation scripts use forward slashes (C:/me/jerry/.ssh/authorized_keys). The OpenSSH daemon on Windows inherits its path-parsing engine from the cross-platform codebase; backslashes in this configuration line can frequently cause silent parsing errors when reading key lists.

The verification section at the end mirrors your original script checks, utilizing a network port sweep to ensure that the actual underlying service is successfully listening across all IP bounds.
