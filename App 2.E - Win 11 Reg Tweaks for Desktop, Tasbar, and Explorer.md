# App 2.E - Windows 11 Desktop, Taskbar, Explorer Registry Tweaks

This `.reg` file applies a set of dev-friendly tweaks for Windows 11, including unactivated VMs. All changes are merged into your registry in one double-click.

## What This `.reg` File Does

### 1. Dark Mode
- Enables dark theme for both apps and system.
- Automatically makes the taskbar dark.

Registry keys:
```registry
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize
  AppsUseLightTheme = 0
  SystemUsesLightTheme = 0
```

### 2. Show File Extensions in Explorer
- Shows file extensions (e.g., `.txt`, `.py`, `.reg`) for all known file types.

Registry key:
```registry
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
  HideFileExt = 0
```

### 3. Taskbar Align Left
- Moves taskbar icons from centered to left-aligned (classic behavior).

Registry key:
```registry
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
  TaskbarAl = 0
```

### 4. Disable News & Interests / Widgets on Taskbar
- Removes the widgets/feeds icon and news from the taskbar.
- Disables the News and Interests feed via policy.

Registry keys:
```registry
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Feeds
  ShellFeedsTaskbarOpenOnHover = 0
  ShellFeedTaskbarViewMode = 2

HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh
  AllowNewsAndInterests = 0
```

### 5. Default to Windows Terminal for PowerShell/CMD/WSL
- Makes PowerShell, Command Prompt, and WSL open in **Windows Terminal** by default.

Registry keys:
```registry
HKEY_CURRENT_USER\Console\%%Startup
  DelegationConsole = {2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}
  DelegationTerminal = {E12CFF52-A866-4C77-9A90-F570A7AA2C6B}
```

### 6. Disable Copilot
- Disables the Windows Copilot AI assistant system-wide.

Registry keys:
```registry
HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsCopilot
  TurnOffWindowsCopilot = 1

HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot
  TurnOffWindowsCopilot = 1
```

### 7. Disable Game DVR / Game Bar
- Turns off Game DVR and Game Bar overlay to reduce background overhead.

Registry keys:
```registry
HKEY_CURRENT_USER\System\GameConfigStore
  GameDVR_Enabled = 0

HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR
  AllowGameDVR = 0
```

### 8. "Open PowerShell Here" Context Menu
- Adds "Open PowerShell here" to:
  - Right-click on folder backgrounds
  - Right-click on folders in Explorer

Registry keys:
```registry
HKEY_CLASSES_ROOT\Directory\Background\shell\PowerShellHere
  @="Open PowerShell here"
  Icon="powershell.exe"

HKEY_CLASSES_ROOT\Directory\Background\shell\PowerShellHere\command
  @="powershell.exe -NoExit -Command \"Set-Location -LiteralPath '%V'\""

HKEY_CLASSES_ROOT\Directory\shell\PowerShellHere
  @="Open PowerShell here"
  Icon="powershell.exe"

HKEY_CLASSES_ROOT\Directory\shell\PowerShellHere\command
  @="powershell.exe -NoExit -Command \"Set-Location -LiteralPath '%V'\""
```

## How to Use

1. Save the content below as `win11-dev-tweaks.reg` (use "All Files" and ensure the extension is `.reg`).
2. Double-click the file.
3. Confirm the merge into the registry.
4. Sign out and back in, or restart Explorer:
   ```powershell
   Stop-Process -Name "explorer" -Force
   ```

## Full `.reg` File Content

```reg
Windows Registry Editor Version 5.00

;.reg file: win11-dev-tweaks.reg
; Applies dev-friendly tweaks for Windows 11 (including unactivated VM)

; === Dark Mode ===
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize]
"AppsUseLightTheme"=dword:00000000
"SystemUsesLightTheme"=dword:00000000

; === Show File Extensions in Explorer ===
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"HideFileExt"=dword:00000000

; === Taskbar Align Left ===
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"TaskbarAl"=dword:00000000

; === Disable News & Interests / Widgets on Taskbar ===
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Feeds]
"ShellFeedsTaskbarOpenOnHover"=dword:00000000
"ShellFeedTaskbarViewMode"=dword:00000002

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh]
"AllowNewsAndInterests"=dword:00000000

; === Default to Windows Terminal for PowerShell/CMD/WSL ===
[HKEY_CURRENT_USER\Console\%%Startup]
"DelegationConsole"="{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
"DelegationTerminal"="{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"

; === Disable Copilot ===
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsCopilot]
"TurnOffWindowsCopilot"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot]
"TurnOffWindowsCopilot"=dword:00000001

; === Disable Game DVR / Game Bar ===
[HKEY_CURRENT_USER\System\GameConfigStore]
"GameDVR_Enabled"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR]
"AllowGameDVR"=dword:00000000

; === Open PowerShell "Here" in Directory & Background Context Menus ===
[HKEY_CLASSES_ROOT\Directory\Background\shell\PowerShellHere]
@="Open PowerShell here"
"Icon"="powershell.exe"

[HKEY_CLASSES_ROOT\Directory\Background\shell\PowerShellHere\command]
@="powershell.exe -NoExit -Command \"Set-Location -LiteralPath '%V'\""

[HKEY_CLASSES_ROOT\Directory\shell\PowerShellHere]
@="Open PowerShell here"
"Icon"="powershell.exe"

[HKEY_CLASSES_ROOT\Directory\shell\PowerShellHere\command]
@="powershell.exe -NoExit -Command \"Set-Location -LiteralPath '%V'\""
```