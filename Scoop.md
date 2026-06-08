Here is the complete reference sheet summarizing the entire lifecycle of Scoop, structured specifically for your custom directory setup.

---

# The Scoop Blueprint: Clean Windows Package Management

## 1. Context & Architecture (Why Scoop?)

Scoop avoids the traditional Windows installer methodology. Instead of running `.exe`/`.msi` files that litter the Windows Registry and drop tracking daemons into background services, Scoop extracts **portable packages** into an isolated workspace.

* **Shims over PATH pollution:** Instead of appending dozens of application directories to your system environment `PATH`, Scoop maintains a single, permanent folder (`\scoop\shims`). It places a tiny execution pointer there for every tool you install.
* **Persist over AppData pollution:** User data, logins, and configurations are mapped to a central `\scoop\persist\` folder via file junctions. Upgrading an app deletes the old version folder cleanly while your user configurations stay pinned to the data hub.

---

## 2. Phase 1: Custom Installation to `C:\me`

To bypass the default user profile path (`C:\Users\jerry\scoop`), you must define your environment targets **before** running the installation string.

Open a standard, **non-admin** PowerShell window and execute these commands in sequence:

```powershell
# 1. Allow execution of local scripts for your user account
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 2. Hardcode the custom paths into your User Environment Profile
$env:SCOOP='C:\me\scoop'
[Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')

$env:SCOOP_GLOBAL='C:\me\scoop\global'
[Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'User')

# 3. Download and execute the Scoop core framework engine
irm get.scoop.sh | iex

```

### The Post-Install Setup (Unlocking Desktop Apps)

By default, Scoop only activates its `main` bucket, which is strictly curated for command-line/developer tools with no GUI. To make it a true system package manager for standard desktop programs (like Bitwarden), unlock the community-maintained `extras` database:

```powershell
scoop bucket add extras

```

---

## 3. Phase 2: App Discovery & Installation

Everything you do from this point onward runs out of your `C:\me\scoop` ecosystem. No admin privileges required.

```powershell
# Search the web and local buckets for an application
scoop search bitwarden

# View details about an app before installing it
scoop info bitwarden

# Install the application cleanly into C:\me\scoop\apps
scoop install bitwarden

```

---

## 4. Phase 3: The Monthly Maintenance Cycle

To keep your system fast and completely pristine, run this short chain of commands once a month.

```powershell
# Step 1: Sync the local manifest databases with upstream GitHub repos
scoop update

# Step 2: Review which apps have newer versions available
scoop status

# Step 3: Atomic upgrade of every outdated application at once
scoop update *

# Step 4: Purge old application versions to recover disk space
scoop cleanup *

```

---

## 5. Phase 4: Querying & System Inspection

When you need to hunt down what is on your system, these commands replace traditional registry/control panel queries:

```powershell
# List all apps managed by Scoop, their versions, and their origin buckets
scoop list

# Check if your Scoop installation has configuration anomalies or path conflicts
scoop checkup

# Show the text manifest configuration for an app (dependencies, download URLs)
scoop cat bitwarden

```

---

## 6. Phase 5: Complete Uninstallation (The Kill Switch)

If you ever decide to drop Scoop entirely, you do not use native uninstall chains or hunt down leftover app remnants across your registry.

Because of the architectural isolation, your **entire** uninstallation strategy consists of a single tool removal command followed by a directory wipe:

```powershell
# Uninstalls all shims and resets system path variables
scoop uninstall scoop

# Wipe the directory. Every file, app, configuration, and binary is 100% gone.
Remove-Item -Recurse -Force C:\me\scoop

```