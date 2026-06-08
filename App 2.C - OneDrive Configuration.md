# App 2.C - OneDrive Configuration

## Objectives

* Maintain a single authoritative location for personal files.
* Avoid duplicate Documents, Downloads, Pictures, and Desktop folders.
* Use OneDrive as backup protection for personal data.
* Keep the architecture centered around `C:\me`.

---

## Design Decision

Canonical personal storage location:

```text
C:\me\jerry
```

Personal files belong here. Avoid creating parallel copies under `C:\Users\Jerry\OneDrive` whenever practical.

---

## Prerequisites and Assumptions

OneDrive must be unlinked and not signed in before proceeding. If OneDrive has previously been signed in, its Known Folder Move (KFM) feature may have already redirected Documents, Pictures, and Desktop into its own folder structure. Attempting to relocate known folders while OneDrive is active risks conflicts, silent reversions, or duplicate folders.

**Verify OneDrive is not active:**

Open Settings → Accounts → Windows backup and confirm OneDrive folder backup is off. Alternatively check the OneDrive system tray icon — it should not show a signed-in account.

**Verify KFM has never run:**

```powershell
Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Personal" `
  | Select-Object UserFolder, KfmFoldersProtectedNow, KfmSilentOptIn
```

Expected output if OneDrive is unlinked:

```
UserFolder KfmFoldersProtectedNow KfmSilentOptIn
---------- ---------------------- --------------
```

All fields empty confirms KFM has not taken ownership of any folders.

**Capture the current known folder baseline:**

```powershell
Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" `
  | Select-Object Desktop, Personal, 'My Pictures', 'My Music', 'My Video', '{374DE290-123F-4565-9164-39C4925E467B}'
```

Before relocation all values should point to `C:\Users\Jerry\...`. If any already point elsewhere, investigate before proceeding.

---

## Create Target Directories

```powershell
$target = "c:\me\jerry"
$folders = @('Desktop','Documents','Pictures','Music','Videos','Downloads')

foreach ($f in $folders) {
    New-Item -Path "$target\$f" -ItemType Directory -Force
}
```

Confirm these were created and the Jerry account has full access:

```text
C:\me\jerry\Desktop
C:\me\jerry\Documents
C:\me\jerry\Downloads
C:\me\jerry\Pictures
C:\me\jerry\Music
C:\me\jerry\Videos
```

---


## Relocate Windows Known Folders

The following PowerShell sets all known folder paths directly in the registry. Run from an elevated prompt.

Downloads is not in the set of  "Windows Known Folders", it is a web browser specification and will need to be set manually for each web browser.

```powershell
$target = "C:\me\jerry"

$shellFolders = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

Set-ItemProperty -Path $shellFolders -Name "Desktop"      -Value "$target\Desktop"
Set-ItemProperty -Path $shellFolders -Name "Personal"     -Value "$target\Documents"
Set-ItemProperty -Path $shellFolders -Name "My Pictures"  -Value "$target\Pictures"
Set-ItemProperty -Path $shellFolders -Name "My Music"     -Value "$target\Music"
Set-ItemProperty -Path $shellFolders -Name "My Video"     -Value "$target\Videos"
```

Then reboot. Windows does not reliably pick up shell folder changes in a running session.

Downloads is intentionally omitted. It is not a standard shell folder and is more easily managed per-browser. See browser configuration documentation.

---


## Verify Known Folder Relocation

```powershell
Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" `
  | Select-Object Desktop, Personal, 'My Pictures', 'My Music', 'My Video'
```

Expected output:

```
Desktop     : C:\me\jerry\Desktop
Personal    : C:\me\jerry\Documents
My Pictures : C:\me\jerry\Pictures
My Music    : C:\me\jerry\Music
My Video    : C:\me\jerry\Videos
```

Also confirm via the .NET enumeration:

```powershell
$folders = @('Desktop','MyDocuments','MyPictures','MyMusic','MyVideos')
foreach ($f in $folders) {
    [System.Environment]::GetFolderPath($f)
}
```

Expected output:

```
C:\me\jerry\Desktop
C:\me\jerry\Documents
C:\me\jerry\Pictures
C:\me\jerry\Music
C:\me\jerry\Videos
```

Both checks should agree. If they disagree, the registry was updated but Windows has not yet picked up the change — reboot and recheck.

---

## Install and Configure OneDrive

Install OneDrive if not already present and sign in using the desired Microsoft account.

During initial setup when prompted to choose the OneDrive folder location, set it to:

```text
C:\me\jerry
```

If OneDrive does not offer this during setup, after sign-in go to OneDrive Settings → Account → Change location and set it to `C:\me\jerry`.

If future OneDrive versions refuse this arrangement, create:

```text
C:\me\jerry\onedrive
```

and document the change. The primary goal is preserving a single obvious location for personal files.

**When OneDrive offers to enable folder backup (KFM), decline.** Known folders have already been relocated to `C:\me\jerry`. Allowing KFM to run at this point will conflict with the existing redirections.

---

## Post-Configuration Validation

Confirm:

```text
OneDrive is signed in and syncing
Files appear in C:\me\jerry
Files appear in OneDrive web interface
Files synchronize correctly
No duplicate Documents folders exist under C:\Users\Jerry
No duplicate Pictures folders exist under C:\Users\Jerry
No duplicate Desktop folders exist under C:\Users\Jerry
```

Note: Windows may recreate empty shell folders under `C:\Users\Jerry` over time. This is normal behavior and can be ignored as long as personal files are not being written there. The goal is not to eliminate `C:\Users\Jerry` but to ensure personal files have a single obvious home at `C:\me\jerry`.