# App 7 - WinPython and Python Tooling 

#### WRITTEN: 2026 Jul, 08 16:33

## SUMMARY

This appendix defines a canonical Python toolchain on Windows centered
on a single WinPython installation used as the "system-ish" interpreter
for third-party applications and operator tooling. Project-level
dependencies and environments are managed with Poetry, while pipx is
used to install global command-line tools in isolated environments. The
configuration ensures that external applications (such as Emacs or
qBittorrent) that accept a Python path or environment variable are
consistently pointed at a single WinPython interpreter, while operator
projects remain isolated and reproducible.

#### TAGS

* windows, python, winpython, poetry, pipx, venv, tools, emacs, qbittorrent

## SCOPE AND CONSTRAINTS

This design applies to a single-user Windows workstation where:

* WinPython is the primary "system-ish" Python distribution.
* The operator maintains multiple Python projects and command-line
  tools.
* Third-party applications (e.g., Emacs, qBittorrent, IDEs) may need a
  Python interpreter specified by absolute path or environment
  variable.

Constraints and assumptions:

* WinPython is installed in a stable, operator-controlled directory
  (e.g., `C:\me\winpy`).
* A single WinPython interpreter is designated as the canonical
  interpreter for external apps and for pipx.
* Poetry is installed as a global CLI via pipx, not inside any project
  environment.
* Project code and operator scripts are allowed to create and use
  per-project virtual environments; system-wide Python installations
  outside WinPython are not relied upon.
* Verification commands (e.g., `python --version`, `pipx --version`,
  `poetry --version`) must be re-run whenever the WinPython version or
  location changes.

## PROCEDURE / USAGE

This section documents the operational steps and current state. All
examples assume PowerShell on Windows.

### 1. Identify the canonical WinPython interpreter

The operator selects a single WinPython interpreter as the canonical
Python for:

* external applications that request a Python executable; and
* global tools installed via pipx.

For concreteness, the canonical interpreter is:

* `c:\me\winpy\python\python.exe`

Verification (run in PowerShell):

```powershell
& 'c:\me\winpy\python\python.exe' --version
```

As of configuration time, this prints a Python 3.14.x version string,
verifying the canonical interpreter path.

### 2. Configure external applications to use WinPython

External applications that need "a Python" must be configured to use
the canonical interpreter path.

Examples:

* qBittorrent search plugins:

  * In qBittorrent's settings (GUI), configure the Python interpreter
    path to the canonical path:

    `c:\me\winpy\python\python.exe`

* Emacs Python integration:

  * For Emacs packages that accept a Python interpreter variable (e.g.,
    `python-shell-interpreter`, LSP backends), set that variable to the
    canonical path.

Configuring Emacs via `.emacs` or `init.el`:

```lisp
(setq python-shell-interpreter
      "C:/WinPython/WPy64-3.14.5.0/python-3.14.5.amd64/python.exe")
```

For Emacs LSP (e.g., eglot or lsp-mode), the interpreter configuration
should align with the same canonical path, or with a project-specific
Poetry environment if desired. The default baseline is to use the
canonical WinPython interpreter for generic or non-project-specific
operations.

### 3. Install pipx using WinPython

pipx is installed with the canonical WinPython interpreter and is used
to manage global command-line tools, including Poetry.

Operational steps:

1. Install pipx using WinPython:

   ```powershell
   & 'c:\me\winpy\python\python.exe' -m pip install pipx
   ```

2. Ensure pipx's "bin" directory is on PATH:

   ```powershell
   & 'c:\me\winpy\python\python.exe' -m pipx ensurepath
   ```

3. Restart the shell, then verify pipx:

   ```powershell
   pipx --version
   ```

This confirms that pipx is installed and that its shim directory is
reachable via PATH.

### 4. Install Poetry via pipx

Poetry is installed as a global CLI tool managed by pipx. It is not
installed into any specific project environment.

Operational steps:

```powershell
pipx install poetry
poetry --version
```

Successful output verifies that Poetry is accessible in the shell and
managed independently of any single project.

### 5. Using Poetry for project environments

For each project directory, Poetry manages per-project environments and
dependencies. These environments are logically distinct from the
canonical WinPython installation and from pipx environments.

#### New project initialization

From a PowerShell prompt:

```powershell
# Create or enter a project directory
cd C:\Projects\example-project

# Initialize Poetry project metadata
poetry init
```

Optional: to force Poetry to use the canonical WinPython interpreter
for this project:

```powershell
poetry env use 'c:\me\winpy\python\python.exe'
```

Poetry will create (or reuse) a per-project virtual environment under
its configured env path, based on the canonical interpreter.

Dependency management:

```powershell
# Add dependencies
poetry add requests

# Install all dependencies from pyproject.toml / poetry.lock
poetry install

# Run commands inside the project's virtual environment
poetry run python -c "import requests; print(requests.__version__)"
```

Verification:

* Running `poetry env info` within the project will show the path to
  the project-specific virtual environment.
* As long as `poetry env use` was called with the canonical WinPython
  path, the environment is based on that interpreter.

### 6. Using pipx for global CLI tools

pipx is used to install command-line applications that should be
available globally but isolated from both WinPython's base environment
and individual Poetry project environments.

Example: install Black and Ruff as global tools:

```powershell
pipx install black
pipx install ruff

black --version
ruff --version
```

These tools now exist in their own pipx-managed environments and
expose command names on PATH. They do not alter the canonical
WinPython base environment or any project's Poetry environment.

External tools (e.g., Emacs) can call these commands directly via PATH
without referencing specific virtual environments.

## IMPLEMENTATION

This section captures reusable scripts and configuration snippets that
implement the described architecture. All filenames and paths should
be adjusted to match the actual WinPython installation location.

### 1. PowerShell helper script: configure environment

The following script:

* Validates the canonical WinPython interpreter.
* Ensures pipx is installed and on PATH.
* Reports the versions of pipx and Poetry.
* Optionally installs Poetry if it is not already present.

This script is intended to be run manually when setting up or verifying
the environment.

#### FILE: Initialize-WinPythonToolchain.ps1

```powershell
param(
    [switch]$InstallPoetry,
    [switch]$Verbose,
    [switch]$Version
)

# Constants: adjust these paths and names as needed
$CanonicalPythonPath = 'c:\me\winpy\python\python.exe'
$PipxModuleName      = 'pipx'
$PoetryCommandName   = 'poetry'

# Script metadata
$ScriptName    = 'Initialize-WinPythonToolchain.ps1'
$ScriptVersion = '1.0.0'

# Simple argument handling for --version / -V and --help / -h
if ($Version) {
    Write-Output "$ScriptName version $ScriptVersion"
    exit 0
}

if ($args -contains '--help' -or $args -contains '-h') {
    Write-Output ''
    Write-Output "$ScriptName - Initialize WinPython-centered Python tooling"
    Write-Output ''
    Write-Output 'Usage:'
    Write-Output '  .\Initialize-WinPythonToolchain.ps1 [-InstallPoetry] [-Verbose] [--help] [--version]'
    Write-Output ''
    Write-Output 'Options:'
    Write-Output '  -InstallPoetry   Install Poetry via pipx if not already present.'
    Write-Output '  -Verbose         Enable verbose output.'
    Write-Output '  --version        Show script version.'
    Write-Output '  --help           Show this help.'
    Write-Output ''
    exit 0
}

# Enable verbose output if requested
if ($Verbose) {
    $VerbosePreference = 'Continue'
}

Write-Verbose "Using canonical Python at: $CanonicalPythonPath"

if (-not (Test-Path -LiteralPath $CanonicalPythonPath)) {
    Write-Error "Canonical Python not found at '$CanonicalPythonPath'. Update the script constants."
    exit 1
}

# Verify Python version
Write-Output "Verifying canonical Python interpreter..."
& $CanonicalPythonPath --version
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to execute canonical Python interpreter."
    exit 1
}

# Ensure pipx is installed
Write-Output "Ensuring pipx is installed and accessible..."

# Try to run pipx directly first
$pipxAvailable = $false
try {
    $pipxVersion = (pipx --version 2>$null)
    if ($pipxVersion) {
        $pipxAvailable = $true
        Write-Output "pipx already available: $pipxVersion"
    }
} catch {
    Write-Verbose "pipx not found on PATH; will attempt to install."
}

if (-not $pipxAvailable) {
    Write-Output "Installing pipx using canonical Python..."
    & $CanonicalPythonPath -m pip install --user $PipxModuleName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "pip install pipx failed."
        exit 1
    }

    Write-Output "Running 'python -m pipx ensurepath'..."
    & $CanonicalPythonPath -m pipx ensurepath
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "pipx ensurepath failed; you may need to adjust PATH manually."
    } else {
        Write-Output "pipx ensurepath completed. You may need to restart your shell."
    }

    # Try pipx again
    try {
        $pipxVersion = (pipx --version 2>$null)
        if ($pipxVersion) {
            $pipxAvailable = $true
            Write-Output "pipx installed: $pipxVersion"
        }
    } catch {
        Write-Warning "pipx still not found on PATH. Check PATH and rerun."
    }
}

if (-not $pipxAvailable) {
    Write-Error "pipx is not available. Aborting."
    exit 1
}

# Optionally install Poetry via pipx
if ($InstallPoetry) {
    Write-Output "Checking for Poetry via pipx..."
    $poetryInstalled = $false

    try {
        $poetryVersion = (poetry --version 2>$null)
        if ($poetryVersion) {
            $poetryInstalled = $true
            Write-Output "Poetry already installed: $poetryVersion"
        }
    } catch {
        Write-Verbose "Poetry not found; will attempt to install via pipx."
    }

    if (-not $poetryInstalled) {
        Write-Output "Installing Poetry via pipx..."
        pipx install $PoetryCommandName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "pipx install poetry failed."
            exit 1
        }

        $poetryVersion = (poetry --version 2>$null)
        if ($poetryVersion) {
            Write-Output "Poetry installed: $poetryVersion"
        } else {
            Write-Warning "Poetry installation completed but 'poetry --version' did not report a version."
        }
    }
}

Write-Output "Initialization complete."
exit 0
```

### 2. Emacs configuration snippet for Python interpreter

The following snippet configures Emacs to use the canonical WinPython
interpreter for generic Python shells. It does not override per-project
LSP or Poetry-specific configurations, which can be layered on top.

```lisp
;; Canonical WinPython interpreter for Emacs Python integration
(setq python-shell-interpreter
      "C:/WinPython/WPy64-3.14.5.0/python-3.14.5.amd64/python.exe")
```

### 3. Example workflow commands for operators

These are not standalone scripts, but represent the canonical operator
workflow for a new project.

```powershell
# Navigate to project directory
cd C:\Projects\example-project

# Initialize Poetry project metadata
poetry init

# Ensure Poetry uses canonical WinPython interpreter for this project
poetry env use 'c:\me\winpy\python\python.exe'

# Add dependencies
poetry add requests

# Verify environment info
poetry env info

# Run a simple test using the project environment
poetry run python -c "import requests; print(requests.__version__)"
```

## DESIGN / OPERATIONAL DECISIONS

Key decisions and rationale:

* Single canonical WinPython interpreter:
  * Using a single WinPython interpreter as the "system-ish" Python
    simplifies configuration of external applications. They all point
    to the same `python.exe`, avoiding ambiguity and version drift.
* pipx for global tools:
  * pipx is used to isolate global command-line tools from both the
    base WinPython environment and project-specific environments,
    reducing dependency conflicts.
* Poetry managed by pipx:
  * Installing Poetry with pipx keeps it out of any single project
    environment and centrally managed, while still isolating its own
    dependencies.
* Poetry as primary project manager:
  * Poetry replaces direct `venv`/`pip` usage for most projects,
    providing per-project environments and lockfiles without manual
    virtualenv management.
* External apps separated from project envs:
  * Emacs, qBittorrent, and similar tools use the canonical WinPython
    interpreter, not individual Poetry envs. This avoids accidental
    coupling between operator projects and application internals.

Notebook-style documentation:

* Commands and configuration snippets are shown inline with the
  explanatory text.
* A single reusable PowerShell script encapsulates environment
  initialization for operator convenience.

## TRADEOFFS

Relevant tradeoffs considered:

* WinPython vs python.org installers:
  * WinPython is chosen for its portable, bundled environment that
    aligns with the operator's existing usage. This comes at the cost
    of diverging from the most common "python.org + py" launcher
    setups.
* Poetry vs simple venv+pip:
  * Poetry introduces an additional tool and mental model, but
    provides lockfiles, standardized metadata, and more robust
    dependency handling. For a single operator with multiple projects,
    the correctness and reproducibility benefits outweigh the added
    complexity.
* pipx vs manual "tools" virtualenv:
  * pipx encapsulates the "per-tool venv + PATH shims" pattern in a
    well-tested tool. A custom "tools" venv would reduce the number of
    tools but increase manual maintenance and risk of dependency
    conflicts.
* Single canonical interpreter vs per-project interpreters:
  * Using one canonical WinPython interpreter simplifies external app
    configuration and tooling. In exchange, upgrading Python requires
    coordinated changes to WinPython and possibly Poetry envs.

## NOTES

* Any change to the canonical WinPython path or version requires:
  * Updating the `CanonicalPythonPath` constant in
    `Initialize-WinPythonToolchain.ps1`.
  * Updating Emacs configuration (`python-shell-interpreter`).
  * Updating external applications (e.g., qBittorrent) that store the
    interpreter path.
* If additional Python distributions are installed (e.g., from
  python.org), care must be taken to avoid "random" `python` on PATH;
  operators should explicitly run the canonical WinPython `python.exe`
  for environment management tasks.
* This appendix overlaps conceptually with any existing appendices
  covering general Python environment management or IDE integration;
  those should be reconciled later to avoid duplication.

## OPEN QUESTIONS

None at this time. The architecture and procedures described here are
considered current and correct for the target workstation.

## SEARCHABLE KEY PHRASES

* winpython poetry pipx setup
* windows canonical python interpreter winpython
* install pipx using winpython python
* poetry env use winpython python exe
* emacs python-shell-interpreter winpython
* qbittorrent search plugins python winpython path
* global cli tools pipx winpython
* poetry pipx winpython operator manual
* windows python toolchain with poetry and pipx
* winpython as system-ish python for apps
