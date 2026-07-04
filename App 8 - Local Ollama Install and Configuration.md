# Ollama Installation and Post-Install Configuration (Windows + Scoop + Custom Model Directory)

## 1. Overview

This document describes a clean Windows setup for Ollama installed via Scoop, including:

* Model storage relocation to `C:\me\ollama`
* Environment variable configuration
* Scheduled Task startup configuration
* CLI and HTTP testing
* What remains in `%USERPROFILE%\.ollama`

---

## 2. Installation (Scoop)

Install Ollama (full build recommended):

```powershell
scoop install ollama-full
```

Verify installation:

```powershell
ollama --version
```

Confirm executable location:

```powershell
Get-Command ollama
```

Expected path:

```text
C:\me\scoop\apps\ollama-full\current\ollama.exe
```

---

## 3. Create Custom Model Directory

Create a dedicated model storage location:

```powershell
mkdir C:\me\ollama\models
```

(Optional) Ensure parent structure:

```powershell
mkdir C:\me\ollama
mkdir C:\me\ollama\models
```

---

## 4. Move Existing Models (if applicable)

If models already exist in default location:

```powershell
move C:\Users\Jerry\.ollama\models C:\me\ollama\
```

---

## 5. Configure Environment Variable (OLLAMA_MODELS)

Set user-level environment variable:

```powershell
[Environment]::SetEnvironmentVariable(
    "OLLAMA_MODELS",
    "C:\me\ollama\models",
    "User"
)
```

Alternative:

```cmd
setx OLLAMA_MODELS C:\me\ollama\models
```

Verify in a new terminal:

```powershell
echo $env:OLLAMA_MODELS
```

Expected output:

```text
C:\me\ollama\models
```

---

## 6. Scheduled Task Setup (Ollama Background Engine)

Ollama runs as a background service using Task Scheduler.

### 6.1 Task configuration (core idea)

Executable:

```text
C:\me\scoop\apps\ollama-full\current\ollama.exe
```

Arguments:

```text
serve
```

Trigger:

* At system startup (BootTrigger)

Run level:

* HighestAvailable

Logon type:

* User (password-based or stored credentials)

---

### 6.2 Recommended creation (PowerShell method)

```powershell
$action = New-ScheduledTaskAction `
    -Execute "C:\me\scoop\apps\ollama-full\current\ollama.exe" `
    -Argument "serve"

$trigger = New-ScheduledTaskTrigger -AtStartup

Register-ScheduledTask `
    -TaskName "Ollama Background Engine" `
    -Action $action `
    -Trigger $trigger `
    -RunLevel Highest
```

---

### 6.3 Important note about environment variables

Scheduled tasks may not always reliably inherit user environment variables.

If issues occur, use a wrapper script:

```powershell
# C:\me\ollama\start-ollama.ps1
$env:OLLAMA_MODELS = "C:\me\ollama\models"
& "C:\me\scoop\apps\ollama-full\current\ollama.exe" serve
```

Then point task to:

```text
pwsh.exe -NoProfile -File C:\me\ollama\start-ollama.ps1
```

---

## 7. Testing the Installation

### 7.1 Check server via browser

Open:

```text
http://localhost:11434/
```

Expected response:

```text
Ollama is running
```

---

### 7.2 Test via curl (HTTP API)

Generate a response:

```powershell
curl http://localhost:11434/api/generate -Method POST -Body (
@{
    model = "llama3.2"
    prompt = "Say hello in one sentence"
} | ConvertTo-Json
)
```

---

### 7.3 Chat via API (streaming alternative)

```powershell
curl http://localhost:11434/api/chat -Method POST -Body (
@{
    model = "llama3.2"
    messages = @(
        @{ role = "user"; content = "Hello, what is Ollama?" }
    )
} | ConvertTo-Json
)
```

---

## 8. CLI Chat Testing

### Start interactive chat session

```powershell
ollama run llama3.2
```

This opens a REPL:

```text
>>> Hello
>>> /bye
```

### One-shot prompt

```powershell
ollama run llama3.2 "Explain what Ollama is in one sentence"
```

---

## 9. Runtime Diagnostics

### Check installed models

```powershell
ollama list
```

### Check active inference sessions

```powershell
ollama ps
```

Note:

* Empty output is normal when no model is actively generating responses

---

## 10. Directory Layout After Setup

### Custom model location (user-controlled)

```text
C:\me\ollama\
    models\
```

### User profile location (left intact)

```text
C:\Users\Jerry\.ollama\
    id_ed25519
    id_ed25519.pub
    cache\
        model-recommendations.json
```

---

## 11. What remains in USERPROFILE and why

The following are intentionally left in `%USERPROFILE%\.ollama`:

### 11.1 SSH identity keys

* `id_ed25519`
* `id_ed25519.pub`

Used for:

* Ollama registry authentication
* identity for model pulling/signing

Not related to Windows SSH

Safe and lightweight

---

### 11.2 Cache directory

* `cache\model-recommendations.json`

Used for:

* model suggestion UI
* registry response caching
* non-critical metadata

Not required for inference
Regenerates automatically if deleted

---

## 12. Final Architecture Summary

Recommended stable configuration:

```text
C:\me\scoop\apps\ollama-full\current\
    ollama.exe

C:\me\ollama\
    models\

C:\Users\Jerry\.ollama\
    identity keys
    small cache metadata
```

---

## 13. Key Takeaways

* Model storage is controlled by `OLLAMA_MODELS`
* Scheduled Task must ensure environment variables are available at startup
* CLI (`ollama run`) is the simplest functional test
* HTTP API (`localhost:11434`) confirms server health
* `ollama ps` only reflects active inference sessions, not installed models
* USERPROFILE `.ollama` contains only identity + lightweight cache and is safe to leave in place
