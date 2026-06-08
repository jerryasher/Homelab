
# App 2.A - Initial Windows Installation and Versioning Update Policy

## Objectives

* Create a stable development workstation.
* Standardize filesystem layout.
* Avoid unnecessary Microsoft account integration during setup.
* Reach a known-good Windows release and remain there until intentionally upgraded.

---

## Initial Installation

Install Windows 11.

Create the primary user account:

```text
Jerry
```

After first login:

```text
C:\Users\Jerry
```

should exist.

---

## Create Standard Directories

Create:

```text
C:\me
C:\me\bin
C:\me\jerry
C:\me\scripts
C:\me\workspace
C:\me\scoop
C:\me\scoopglobalapps
```

## Create Target Directories

```powershell

$root = "c:\me"
New-Item -Path "$root" -ItemType Directory -Force

$folders = @('bin', 'jerry', 'scripts', 'workspace', 'scoop', 'scoopglobalapps')

foreach ($f in $folders) {
    New-Item -Path "$root\$f" -ItemType Directory -Force
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


Verify that the Jerry account has full access.

---

## Initial Updates

Install:

* Windows Updates
* Device drivers
* Hardware vendor updates

Reboot as required.

Continue until no further updates are offered.

---

## Windows Version Pinning Policy

Target:

```text
Windows 11 24H2
```

Rationale:

* Current mainstream release.
* Large user base.
* Most software compatibility issues already discovered.
* Avoid constant feature churn.

---

## Pinning Feature Updates

Open:

```text
gpedit.msc
```

Navigate to:

```text
Computer Configuration
Administrative Templates
Windows Components
Windows Update
Manage updates offered from Windows Update
```

Open:

```text
Select the target Feature Update version
```

Enable the policy.

Set:

```text
Product Version:
Windows 11

Target Version:
24H2
```

Apply.

Here is an alternate equivalent way of doing this when run from an elevated powershell

```powershell

$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (!(Test-Path $policyPath)) { New-Item -Path $policyPath -Force }

$settings = @{
    "TargetReleaseVersion"     = 1
    "TargetReleaseVersionInfo" = "24H2"
    "ProductVersion"           = "Windows 11"
}

foreach ($name in $settings.Keys) {
    Set-ItemProperty -Path $policyPath -Name $name -Value $settings[$name] -Force
}

gpupdate /force

```


### Verify Version Pinning Policy Application

Open an elevated PowerShell prompt and run:

```powershell
gpresult /r /scope computer
```

Under **COMPUTER SETTINGS → Applied Group Policy Objects**, confirm:

```text
Local Group Policy
```

If it appears there (not under the filtered-out list), the computer-side GPO applied successfully.

Then confirm the specific Windows Update registry values were written:

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
  | Select-Object TargetReleaseVersion, TargetReleaseVersionInfo
```

Expected output:

```
TargetReleaseVersion     : 1
TargetReleaseVersionInfo : 24H2
```

Both checks passing confirms the feature update pin is active and Windows Update will respect it.

Note: `gpresult /r` without `/scope computer` only shows user-scoped policy and will not reflect this setting. The elevated shell is required for the computer-scope query.

```powershell
# Combined Version and Policy Check
$OSInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsDisplayVersion
$RegInfo = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction SilentlyContinue

Write-Host "Current OS: $($OSInfo.OsDisplayVersion)" -ForegroundColor Cyan
if ($RegInfo.TargetReleaseVersionInfo -eq "24H2") {
    Write-Host "Policy Match: Target 24H2 is ACTIVE" -ForegroundColor Green
} else {
    Write-Host "Policy Mismatch: Check GPO Settings" -ForegroundColor Red
}

```

---

## Post-Install Validation

Confirm:

```text
C:\me exists
Windows fully updated
Drivers installed
User account functioning
Network functioning
```

Proceed to OneDrive configuration.
