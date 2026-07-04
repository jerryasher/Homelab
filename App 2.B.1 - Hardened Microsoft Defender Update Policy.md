# 📄 Hardened Microsoft Defender‑Only Update Setup  
### *(No Windows Update Channel — With Update Medic & Firewall Hardening)*

```markdown
# Hardened Microsoft Defender-Only Update Setup
## No Windows Update Channel • Update Medic Neutralized • Firewall-Enforced Isolation

This document describes how to configure Windows 11 so that:
- **Microsoft Defender Antivirus updates continue normally**
- **Windows Update is fully blocked**
- **Update Medic Service cannot revive Windows Update**
- **No cumulative updates, drivers, .NET updates, preview updates, or feature updates install**
- **Only Defender’s own update channels (MMPC) are allowed**

This is the strongest possible “Defender-only update” configuration.

---

# 1. Update Defender Without Windows Update

## 1.1 Signature Updates (PowerShell)
Run in PowerShell (Admin):

```
Update-MpSignature
```

Updates:
- Virus signatures  
- Spyware signatures  
- Network protection signatures  

Uses Defender’s own update channel, not Windows Update.

---

## 1.2 Full Defender Platform + Engine Update
Run from Defender’s actual directory:

```
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
```

or on newer builds:

```
"%ProgramFiles%\Microsoft Defender\MpCmdRun.exe" -SignatureUpdate
```

Updates:
- Antimalware platform (KB4052623 component)  
- Scanning engine  
- All signature types  

Still bypasses Windows Update.

---

# 2. Force Defender to Use MMPC Only (Not Windows Update)

Open Group Policy Editor:

```
Computer Configuration
→ Administrative Templates
→ Windows Components
→ Microsoft Defender Antivirus
→ Signature Updates
```

Configure:

### 2.1 Define the order of sources for downloading security intelligence updates
Enable and set:

```
Microsoft Update Server
MMPC
FileShares
```

### 2.2 Allow updates from Windows Update
Set to **Disabled**

This forces Defender to use its own update endpoints.

---

# 3. Disable Windows Update Components

Open Group Policy Editor:

```
Computer Configuration
→ Administrative Templates
→ Windows Components
→ Windows Update
→ Manage end user experience
```

Configure:

### 3.1 Configure Automatic Updates
Set to **Disabled**

### 3.2 Do not include drivers with Windows Updates
Set to **Enabled**

### 3.3 Get the latest updates as soon as they're available
Set to **Disabled**

### 3.4 Select when Preview Builds and Feature Updates are received
Enable and set:
- **Channel:** Stable  
- **Target Version:** 24H2  

This prevents:
- Preview updates  
- Feature updates  
- CFR feature rollouts  
- Optional updates  

---

# 4. Understanding Update Medic Service (WaaSMedicSvc)

## 4.1 What Update Medic Does
Update Medic Service is Windows Update’s “self-healing” component. It:
- Re-enables disabled Windows Update services  
- Repairs update components  
- Resets registry keys  
- Overrides Group Policy if it believes updates are “required”  
- Forces Windows Update to run even when you disable it  

## 4.2 Why Policies Alone Are Not Enough
Update Medic can:
- Restart `wuauserv`, `bits`, `dosvc`  
- Undo your GPO settings  
- Reset your registry keys  
- Attempt to install cumulative updates even when blocked  

**It cannot bypass firewall rules.**

This is why firewall blocking is mandatory for a true Defender-only setup.

---

# 5. Firewall Blocking (The Critical Layer)

## 5.1 Block Windows Update Endpoints

Block outbound traffic to:

```
*.windowsupdate.com
*.update.microsoft.com
*.dl.delivery.mp.microsoft.com
*.delivery.mp.microsoft.com
*.msftconnecttest.com
```

These are used for:
- Cumulative updates  
- Feature updates  
- Driver updates  
- Servicing stack updates  
- Preview updates  

Medic cannot bypass firewall blocks.

---

## 5.2 Allow Defender Endpoints

Allow outbound traffic to:

```
*.mp.microsoft.com
*.definitionupdates.microsoft.com
```

These are used for:
- Defender signatures  
- Defender platform updates  

---

## 5.3 PowerShell Firewall Rules

### Block Windows Update
```
New-NetFirewallRule -DisplayName "Block Windows Update" -Direction Outbound -Action Block -RemoteAddress windowsupdate.com,update.microsoft.com,dl.delivery.mp.microsoft.com
```

### Allow Defender
```
New-NetFirewallRule -DisplayName "Allow Defender Updates" -Direction Outbound -Action Allow -RemoteAddress mp.microsoft.com,definitionupdates.microsoft.com
```

This creates a hardened split:
- **Defender updates succeed**
- **Windows Update fails permanently**
- **Medic cannot revive Windows Update**

---

# 6. Optional: Scheduled Task for Automatic Defender Updates

Create a SYSTEM-level scheduled task:

```
schtasks /create /tn "DefenderSignatureUpdate" ^
/tr "\"%ProgramFiles%\Windows Defender\MpCmdRun.exe\" -SignatureUpdate" ^
/sc hourly /ru SYSTEM
```

This keeps Defender updated without Windows Update.

---

# 7. Result

You now have a hardened configuration where:
- Defender updates continue normally  
- Windows Update is permanently blocked  
- Update Medic cannot undo your settings  
- No cumulative updates, drivers, .NET updates, preview updates, or feature updates install  
- Only Defender’s own update channels (MMPC) are used  

This is the strongest possible “Defender-only update” setup on Windows 11.
```

---

If you want, I can also generate:

- A firewall-only lockdown document  
- A document explaining how Medic bypasses GPO  
- A combined 24H2 lockdown + Defender-only strategy