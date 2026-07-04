# Scoop Maintenance Guide

## Overview

Scoop is a package manager for Windows that installs applications into your user profile without requiring administrator privileges. Unlike many package managers, Scoop intentionally keeps older versions of applications after an upgrade so that you can easily roll back if a newer version has problems.

A complete Scoop maintenance cycle consists of:

1. Install an application.
2. Update Scoop itself.
3. Update installed applications.
4. Verify everything works.
5. Remove older installed versions.
6. Remove cached installer downloads.
7. Periodically remove unused Ollama models (if applicable).

---

# Installing Applications

Install an application:

```powershell
scoop install git
scoop install vscode
scoop install ollama
```

Applications are typically installed under:

```text
%USERPROFILE%\scoop\apps
```

For example:

```text
C:\Users\Jerry\scoop\apps\vscode
```

---

# Updating Scoop

Update Scoop itself before updating applications:

```powershell
scoop update
```

This updates Scoop's own code and bucket metadata.

---

# Updating Installed Applications

Update every installed application:

```powershell
scoop update *
```

Alternatively, update a single application:

```powershell
scoop update vscode
```

If an application has no newer version available, nothing is downloaded.

If a newer version exists, Scoop downloads the complete installer/archive and installs it beside the existing version.

Example:

```text
apps\vscode
    1.124.0
    1.125.0
    1.126.0
    current -> 1.126.0
```

The `current` junction points to the active version.

---

# Why Old Versions Are Kept

Scoop intentionally leaves previous versions installed.

Benefits include:

* Easy rollback if a new version is broken.
* Ability to compare behavior between versions.
* Safe upgrades without immediately deleting the previous release.

After you've confirmed the new version works correctly, the older versions can be removed.

---

# Cleaning Up Older Installed Versions

Clean up one application:

```powershell
scoop cleanup vscode
```

Clean up every installed application:

```powershell
scoop cleanup *
```

This removes old installed versions but leaves the current version intact.

---

# Cleaning the Download Cache

Whenever Scoop downloads an installer or ZIP archive, it stores a copy in its cache.

These cached downloads accumulate over time.

View cached files for an application:

```powershell
scoop cache show vscode
```

Remove cached files for one application:

```powershell
scoop cache rm vscode
```

Remove all cached installers:

```powershell
scoop cache rm *
```

Cleaning the cache does **not** uninstall any applications.

---

# Recommended Maintenance Cycle

A typical maintenance cycle is:

```powershell
scoop update
scoop update *
```

Verify that your important applications still work.

Then clean up:

```powershell
scoop cleanup *
scoop cache rm *
```

Some users prefer waiting a day or two before running `scoop cleanup *` so that rolling back to the previous version remains easy if necessary.

---

# Skipping Large Applications Such as Ollama

Scoop currently does not provide an `--exclude` option for:

```powershell
scoop update *
```

If you would rather avoid downloading large updates for applications such as Ollama every time you update, a small PowerShell function is convenient.

Example:

```powershell
function Update-ScoopApps {
    $exclude = @(
        'ollama'
    )

    (scoop list).Name |
        Where-Object { $_ -notin $exclude } |
        ForEach-Object {
            scoop update $_
        }
}
```

Now your normal update process becomes:

```powershell
scoop update
Update-ScoopApps
```

Whenever you decide you want the newest Ollama release:

```powershell
scoop update ollama
```

## Excluding Multiple Applications

Simply extend the exclusion list:

```powershell
function Update-ScoopApps {
    $exclude = @(
        'ollama',
        'vscode',
        'powershell'
    )

    (scoop list).Name |
        Where-Object { $_ -notin $exclude } |
        ForEach-Object {
            scoop update $_
        }
}
```

This makes it easy to postpone updates for particularly large or critical applications.

---

# Ollama Models

The Scoop package installs the Ollama application.

The language models are **not** managed by Scoop.

They are typically stored under:

```text
%USERPROFILE%\.ollama\models
```

Models are often much larger than the Ollama application itself. Individual models commonly range from several gigabytes to tens of gigabytes.

Examples include:

* llama3
* gemma
* qwen
* mistral

Updating or removing the Scoop package does **not** affect these models.

---

# Viewing Installed Models

List installed models:

```powershell
ollama list
```

Example output:

```text
NAME            SIZE
llama3:8b       4.7 GB
qwen3:14b       9.1 GB
gemma3:12b      8.2 GB
```

---

# Removing Models

Delete a model you no longer need:

```powershell
ollama rm llama3:8b
```

Remove another model:

```powershell
ollama rm qwen3:14b
```

After removing a model, the associated disk space is reclaimed.

To verify the remaining models:

```powershell
ollama list
```

---

# Summary

A straightforward Scoop maintenance workflow is:

```powershell
scoop update
Update-ScoopApps
```

Test that your applications work as expected.

Then clean up:

```powershell
scoop cleanup *
scoop cache rm *
```

Occasionally review your Ollama models:

```powershell
ollama list
ollama rm <model-name>
```

Following this process keeps installed applications current while minimizing unnecessary disk usage from old application versions, cached installer downloads, and unused language models.
