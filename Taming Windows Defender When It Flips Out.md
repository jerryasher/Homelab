# Taming Windows Defender When It Flips Out

## Overview

Microsoft Defender is highly scriptable through PowerShell.

For many administrative tasks it is much faster and less frustrating
than the Windows Security UI.

The examples below assume an elevated (Administrator) PowerShell session.

---

# Temporarily Pause Defender

## Using the Windows Security UI

1. Open **Windows Security**.
2. Select **Virus & threat protection**.
3. Under **Virus & threat protection settings**, click **Manage settings**.
4. Turn **Real-time protection** Off.
5. If Tamper Protection prevents this, temporarily disable **Tamper Protection** first.

Remember to turn Real-time Protection and Tamper Protection back on when finished.

## Using PowerShell

Disable real-time protection:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
```

Re-enable it:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
```

Check Defender status:

```powershell
Get-MpComputerStatus
```

---

# View Threats and Detection History

Current threats known to Defender:

```powershell
Get-MpThreat
```

Detailed detection history:

```powershell
Get-MpThreatDetection
```

Useful view:

```powershell
Get-MpThreatDetection |
    Select InitialDetectionTime,
           ProcessName,
           Resources,
           ThreatID,
           ThreatStatusID
```

The important fields are:

* `ProcessName` - the process that triggered the detection.
* `Resources` - the file or object Defender detected.
* `ThreatID` - Defender's internal classification.
* `ThreatStatusID` - current state of the detection.

A common example is:

```
ProcessName:
C:\me\scoop\apps\everything-beta\...\Everything.exe

Resources:
...\mailpv.exe
```

This does **not** mean Everything is malware. It means Everything accessed a file (`mailpv.exe`) that Defender considers suspicious.

---

# Protection History

The Windows Security UI displays Protection History:

1. Open **Windows Security**.
2. Select **Virus & threat protection**.
3. Open **Protection history**.

This shows:

* Detected threats
* Quarantined items
* Allowed items
* Remediation actions

PowerShell can display detection history, but it does not provide a complete equivalent to the Protection History UI.

---

# Restoring Quarantined Files

The Windows Security UI supports restoring quarantined files.

1. Open **Protection history**.
2. Select the detection.
3. Choose **Actions**.
4. Select **Restore** or **Allow on device**.

PowerShell does not currently expose a supported cmdlet for restoring quarantined files. Restoration generally must be performed through the Windows Security UI or by using the Microsoft Defender command-line utility (`MpCmdRun.exe`) for supported scenarios.

---

# Whitelisting Files and Folders

## Windows Security UI

1. Open **Windows Security**.
2. Select **Virus & threat protection**.
3. Click **Manage settings**.
4. Select **Add or remove exclusions**.
5. Click **Add an exclusion**.
6. Choose File, Folder, Process, or File Type.

For NirSoft, excluding a folder is usually the simplest approach.

---

## PowerShell

Add a folder exclusion:

```powershell
Add-MpPreference -ExclusionPath "C:\me\bin\nirsoft"
```

View exclusions:

```powershell
(Get-MpPreference).ExclusionPath
```

Remove an exclusion:

```powershell
Remove-MpPreference -ExclusionPath "C:\me\bin\nirsoft"
```

---

# Downloading the NirSoft Tool Collection

Create the destination directory:

```powershell
New-Item -ItemType Directory -Force `
    -Path "C:\me\bin\nirsoft"
```

Download the ZIP archive:

```powershell
Invoke-WebRequest `
    -Uri "https://www.nirsoft.net/packages/x64tools.zip" `
    -OutFile "$env:TEMP\nirsoft.zip"
```

Extract the password-protected archive using 7-Zip:

```powershell
& "C:\Program Files\7-Zip\7z.exe" x `
    "$env:TEMP\nirsoft.zip" `
    "-oC:\me\bin\nirsoft" `
    -pnirsoft123!
```

Delete the ZIP file:

```powershell
Remove-Item "$env:TEMP\nirsoft.zip"
```

---

# Whitelist the NirSoft Folder

```powershell
Add-MpPreference -ExclusionPath "C:\me\bin\nirsoft"
```

Verify:

```powershell
(Get-MpPreference).ExclusionPath
```

---

# Add the Folder to PATH

For the current user:

```powershell
$current = [Environment]::GetEnvironmentVariable("Path", "User")

if ($current -notlike "*C:\me\bin\nirsoft*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$current;C:\me\bin\nirsoft",
        "User"
    )
}
```

Restart PowerShell (or sign out and back in) for the updated PATH to take effect.

You can verify:

```powershell
$env:Path -split ';'
```
