GPT-5.5: June 27, 2026 00:32 PDT GPT-5.5

Here is a clean markdown document you can reuse.

# MarkText .md Open-With Issue on Windows 11 (Scoop Install)

## Summary

A Scoop-installed MarkText application on Windows 11 failed to open `.md` files via File Explorer (“Open with…” loop), while working correctly from PowerShell command line. The issue was resolved by resetting the `.md` default application to Notepad via Windows Settings and then reassigning it to MarkText using the GUI workflow.

---

## Symptoms

* Double-clicking `.md` files initially failed to reliably open MarkText.
* Selecting MarkText via “Open with…” caused the file picker dialog to reappear in a loop.
* MarkText worked correctly when launched from PowerShell:

  * `marktext file.md` opened files normally.
* Notepad worked correctly when set as the default `.md` handler.
* CLI tools showed inconsistent or restricted behavior:

  * `assoc .md` returned “Access is denied.”
  * `ftype` could not define a `markdown` handler.

---

## Investigation Findings

### 1. PowerShell Registry Path Confusion (false lead)

Initial registry inspection attempts failed because registry paths were not correctly prefixed with `HKCU:\`.

This caused PowerShell to interpret registry paths as filesystem paths under the current working directory, producing misleading “path not found” errors.

---

### 2. Windows File Association State

The `.md` extension was in a partially inconsistent state:

* Windows Explorer used the modern per-user association system.
* Legacy Win32 mapping (`assoc`) reported no valid file association.
* `assoc .md` returned:

  * “File association not found for extension .md”

This indicates the Win32 association layer was not authoritative for `.md`.

---

### 3. CLI vs GUI Association Conflict

* CLI tools (`assoc`, `ftype`) were blocked or ineffective due to Windows 11 protection of per-user file associations.
* Windows required GUI-based changes via Settings to modify `.md` associations.
* MarkText, being a portable Scoop-installed application, did not behave like a fully registered Windows “default app handler,” causing Explorer’s “Open with” workflow to fail validation.

---

## Root Cause

The issue was caused by a mismatch between:

1. Windows 11 modern per-user file association system
2. Lack of a fully registered default-app contract for MarkText (portable Scoop install)
3. A partially inconsistent `.md` association state where:

   * GUI layer could set defaults
   * CLI layer could not modify associations
   * Explorer failed to validate MarkText as a default handler, causing fallback loop behavior

---

## Resolution

The issue was resolved by resetting and reassigning the `.md` association through Windows Settings:

### Step 1: Reset default application

* Opened:

  * `ms-settings:defaultapps`
* Changed `.md` association to Notepad

This restored a known-good baseline handler.

### Step 2: Reassign to MarkText via GUI

* Used “Open with → Choose another app”
* Selected MarkText executable directly
* Confirmed “Always use this app”

After this reset, Windows correctly accepted MarkText as the handler.

---

## Why This Worked

Resetting to Notepad forced Windows to:

* Clear inconsistent per-user association state
* Rebuild internal mapping for `.md`
* Re-establish a valid default-app contract

Reassigning MarkText afterward succeeded because the system was no longer in a broken transition state between:

* legacy Win32 association model
* modern AppX-style default app enforcement

---

## Key Lessons

* Windows 11 file associations for common extensions like `.md` may bypass Win32 tools (`assoc`, `ftype`).
* Portable applications (like Scoop installs) may not register as full default-app handlers.
* When `.md` associations become inconsistent:

  * CLI tools may fail or be ignored
  * Settings UI reset is often required to restore a stable state
* PowerShell registry paths must use `HKCU:\` syntax or they will be interpreted as filesystem paths.

---

## Outcome

* `.md` files open correctly in MarkText via Explorer
* PowerShell invocation remains functional
* System file associations are stable again
