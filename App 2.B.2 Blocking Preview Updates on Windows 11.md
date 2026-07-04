# Blocking Preview Updates on Windows 11

This document explains how to block all preview updates (C/D releases) so that
only mandatory Patch Tuesday security updates are ever offered.

---

## 1. Block Preview Updates via Group Policy

Open Group Policy Editor:

```
Computer Configuration
→ Administrative Templates
→ Windows Components
→ Windows Update
→ Manage end user experience
```

Configure:

### **Enable optional updates**
Set to **Disabled**

This blocks:
- Preview cumulative updates
- Optional driver updates
- Optional .NET previews

---

## 2. Block Preview Builds and Feature Rollouts

Navigate to:

```
Computer Configuration
→ Administrative Templates
→ Windows Components
→ Windows Update
→ Windows Update for Business
```

Configure:

### **Select when Preview Builds and Feature Updates are received**
Enable and set:
- **Channel:** Stable
- **Target Version:** 24H2

This prevents:
- Preview builds
- CFR feature rollouts
- Feature updates beyond 24H2

---

## 3. Disable “Get the latest updates as soon as they’re available”

Navigate to:

```
Computer Configuration
→ Administrative Templates
→ Windows Components
→ Windows Update
→ Manage end user experience
```

Set:

### **Get the latest updates as soon as they're available**
→ **Disabled**

This blocks Microsoft’s “early adopter” preview pipeline.

---

## 4. Optional: Registry Enforcement

Create the following registry keys:

```
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate]
"DoNotOfferOptionalUpdates"=dword:00000001
"ManagePreviewBuilds"=dword:00000000
"TargetReleaseVersion"=dword:00000001
"TargetReleaseVersionInfo"="24H2"
```

This enforces:
- No preview updates
- No optional updates
- No feature updates beyond 24H2

---

## Result

Your system will:
- Receive only mandatory Patch Tuesday security updates
- Never receive preview updates
- Never receive optional updates
- Never receive feature updates beyond 24H2
```

