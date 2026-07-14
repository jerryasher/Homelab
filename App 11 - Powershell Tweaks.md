# PowerShell History: Bigger Limits and Easy Search

This document summarizes how to increase PowerShell’s history size permanently and how to search both the in‑memory history and the persistent disk store (PSReadLine history), analogous to `history | grep <pattern>` on Linux.

---

## 1. Two histories in PowerShell

PowerShell actually tracks history in two different places. [web:14][web:55]

- **Built‑in session history**
  - Accessed with `Get-History` (alias `history`, `h`). [web:14]
  - Only includes commands from the *current* session.
  - Size controlled by `$MaximumHistoryCount`.
  - Cleared when the session ends. [web:14]

- **PSReadLine persistent history**
  - Managed by the PSReadLine module (loaded by default in modern PowerShell). [web:14][web:56]
  - Saved in a text file at `(Get-PSReadLineOption).HistorySavePath`.
  - Shared across sessions; not cleared when a session ends. [web:14][web:56]
  - Not directly affected by `Get-History` / `*-History` cmdlets. [web:14][web:55]

This is roughly analogous to Bash’s in‑memory history (`HISTSIZE`) vs `~/.bash_history`, but implemented as two separate providers. [web:14][web:45]

---

## 2. Increasing the in‑memory history size permanently

### 2.1 `$MaximumHistoryCount` (built‑in history)

The built‑in history size is controlled by the `$MaximumHistoryCount` preference variable. [web:14][web:58]

- Default value: 4096 commands. [web:14]
- It limits how many entries `Get-History` can return for the current session. [web:14]
- To change it for the current session:

```powershell
$MaximumHistoryCount = 32767
```

While you might want “50K commands,” the effective maximum supported value is 32767. [web:56] That’s close to 50K and is large enough for most workflows.

To make this permanent, add it to your PowerShell profile:

```powershell
notepad $PROFILE
```

Then add:

```powershell
$MaximumHistoryCount = 32767
```

Save and restart PowerShell; all new sessions will use this larger in‑memory history size. [web:14][web:58]

### 2.2 PSReadLine’s own limit

PSReadLine also has a `MaximumHistoryCount` setting, which controls how many commands it keeps in its own in‑memory buffer and in the history file. [web:56]

Check current settings:

```powershell
Get-PSReadLineOption
```

Typical output includes:

```text
HistorySavePath      : C:\Users\you\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
MaximumHistoryCount  : 4096
HistorySaveStyle     : SaveIncrementally
```

To increase PSReadLine’s internal limit:

```powershell
Set-PSReadLineOption -MaximumHistoryCount 50000
```

Add that to your profile to make it persistent:

```powershell
notepad $PROFILE
```

```powershell
$MaximumHistoryCount = 32767
Set-PSReadLineOption -MaximumHistoryCount 50000
```

Now:

- `Get-History` can use up to ~32K commands in the current session. [web:14][web:56]
- PSReadLine can maintain a larger rolling history across sessions, up to its `MaximumHistoryCount`. [web:56]

---

## 3. Where the persistent history lives

PSReadLine stores its persistent history in a text file. [web:14][web:5][web:8]

Get its exact path:

```powershell
(Get-PSReadLineOption).HistorySavePath
```

Typical Windows path (PowerShell console):

```text
C:\Users\<username>\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
```

You can inspect it directly:

```powershell
# View in Notepad
notepad (Get-PSReadLineOption).HistorySavePath

# Or as raw text
Get-Content (Get-PSReadLineOption).HistorySavePath
```

This file is the equivalent of Bash’s `~/.bash_history`: it accumulates commands across sessions and survives closing the shell. [web:14][web:5][web:8]

---

## 4. Searching the current session’s history (Get-History side)

To search only the current session’s built‑in history (bounded by `$MaximumHistoryCount`), you can filter `Get-History` output.

### 4.1 Basic pattern search

```powershell
# Case-insensitive substring match
Get-History | Where-Object CommandLine -imatch 'pattern'
```

Examples:

```powershell
Get-History | Where-Object CommandLine -imatch 'winget install'
Get-History | Where-Object CommandLine -imatch 'docker cp'
```

This is similar to `history | grep 'pattern'` in Linux, but it only sees the commands present in the *current* PowerShell session, up to the in‑memory limit. [web:14]

### 4.2 Show just the command text

To show only the command text without IDs and metadata:

```powershell
Get-History |
  Where-Object CommandLine -imatch 'pattern' |
  Select-Object -ExpandProperty CommandLine
```

---

## 5. Searching the persistent disk history (PSReadLine side)

For “very old commands” across sessions, you should search the PSReadLine history file rather than `Get-History`. [web:14][web:60][web:5]

### 5.1 `Select-String` over the history file

The simplest approach:

```powershell
$histFile = (Get-PSReadLineOption).HistorySavePath
Select-String -Path $histFile -Pattern 'pattern'
```

Examples:

```powershell
# Find every command that mentioned ffmpeg
Select-String -Path (Get-PSReadLineOption).HistorySavePath -Pattern 'ffmpeg'

# Find old "winget install" commands
Select-String -Path (Get-PSReadLineOption).HistorySavePath -Pattern 'winget install'
```

This behaves much like `grep pattern ~/.bash_history`, showing each matching line from your entire persistent history file. [web:5][web:60]

To print only the command text:

```powershell
Select-String -Path (Get-PSReadLineOption).HistorySavePath -Pattern 'pattern' |
    ForEach-Object { $_.Line }
```

### 5.2 Linux‑style `grep` alias

If you want muscle‑memory compatibility with Linux:

```powershell
Set-Alias grep Select-String
```

Now you can do:

```powershell
grep 'pattern' (Get-PSReadLineOption).HistorySavePath
```

Or:

```powershell
Get-Content (Get-PSReadLineOption).HistorySavePath | grep 'pattern'
```

This mimics `history | grep pattern` by searching the full persistent history store. [web:5][web:60]

### 5.3 Reusable helper function (PowerShell “history grep”)

Add a small wrapper function to your profile:

```powershell
function Search-History {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    $historyFile = (Get-PSReadLineOption).HistorySavePath
    if (-not (Test-Path $historyFile)) {
        Write-Warning "History file not found: $historyFile"
        return
    }

    Select-String -Path $historyFile -Pattern $Pattern |
        ForEach-Object { $_.Line }
}
```

Usage:

```powershell
Search-History 'winget install'
Search-History 'pip install'
Search-History 'docker cp'
```

This is very close to:

```bash
history | grep 'pattern'
```

but operates on the long‑term PSReadLine history file, not just the current session. [web:5][web:60]

---

## 6. Keyboard‑driven search (no typing commands)

PSReadLine also supports interactive incremental search using key bindings. [web:55][web:14][web:60]

Useful keys (when PSReadLine is active):

- `Ctrl+R` – Search backward in history; type part of a command, press `Ctrl+R` to cycle matches. [web:55][web:60]
- `Ctrl+S` – Search forward in history. [web:55][web:60]
- `F8` / `Shift+F8` – Search for history entries that *start with* the current input. [web:14][web:60]

This searching operates over PSReadLine’s history, including entries from other sessions that are stored in the history file. [web:55][web:60]

---

## 7. Summary: Mapping to the Linux mental model

**Goal:** “Make PowerShell history huge and easily searchable, like `history | grep <pattern>` in Linux.”

- Increase in‑memory history:
  - Set `$MaximumHistoryCount = 32767` in your profile. [web:14][web:56]
  - Optionally, `Set-PSReadLineOption -MaximumHistoryCount 50000` to extend PSReadLine’s buffer. [web:56]

- Persistent history store:
  - Use PSReadLine’s file: `(Get-PSReadLineOption).HistorySavePath`. [web:5][web:8][web:60]

- Search current session:
  - `Get-History | Where-Object CommandLine -imatch 'pattern'`. [web:14]

- Search all sessions (disk store):
  - `Select-String -Path (Get-PSReadLineOption).HistorySavePath -Pattern 'pattern'`. [web:5][web:60]
  - Or via helper: `Search-History 'pattern'`.

With these in place, PowerShell gives you both a large rolling interactive history and a long‑term searchable audit trail of your commands, covering the “how did I install this last month?” use case very well. [web:14][web:5][web:60]
