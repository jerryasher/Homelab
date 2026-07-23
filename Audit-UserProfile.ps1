<#
.SYNOPSIS
Read-only audit of an old Windows user profile and system dependencies.

.DESCRIPTION
Designed to answer: "Can I safely delete this profile?"

Audit-UserProfile inspects a user profile directory and the surrounding
system (registry, scheduled tasks, services, file references, etc.) for
signs that something outside the profile still depends on it.

It never modifies or deletes anything — it only reads and reports.
Findings are written to both the console (color-coded) and a timestamped
log file in the current directory.

You can control which parts of the audit run using the -Sections and
-Skip parameters, making it easy to focus on specific areas or skip
expensive checks.

.PARAMETER UserName
The local account name to audit. Defaults to "JerryAdmin".

.PARAMETER ProfilePath
Full path to the profile directory to audit
(e.g. "C:\Users\JerryAdmin").  Defaults to "C:\Users\JerryAdmin".

.PARAMETER Sections
Array of substrings. Only sections whose name matches at least one of
these will run. Useful for running just part of the audit.

.PARAMETER Skip
Array of substrings. Any section whose name matches one of these will be
skipped (takes precedence over -Sections).

.PARAMETER ListSections
Lists all available sections in the script, shows their current status
(Enabled / Filtered Out / SKIPPED) based on the -Sections and -Skip
parameters, then exits. Highly recommended when learning the script.

.EXAMPLE
.\Audit-UserProfile.ps1

Runs the full audit on the default profile (JerryAdmin).

.EXAMPLE
.\Audit-UserProfile.ps1 -ListSections

Shows all available sections with their status and exits.

.EXAMPLE
.\Audit-UserProfile.ps1 -ListSections -Skip "Registry","Autoruns"

Shows what would run if you skip certain heavy sections.

.EXAMPLE
.\Audit-UserProfile.ps1 -Sections "Profile","Permissions","HKCU" 

Runs only sections related to the profile directory, permissions, and
the user's registry hive.

.EXAMPLE
.\Audit-UserProfile.ps1 -UserName "OldContractor" `
                        -ProfilePath "D:\Users\OldContractor" `
                        -Skip "Ownership"

Audits a profile on a different drive and skips the file ownership check.

.NOTES
- Must be run from an elevated (Administrator) PowerShell session.
- Completely read-only: it loads NTUSER.DAT temporarily but makes no changes 
  to the system.
- DPAPI-protected secrets (Credential Manager, Wi-Fi passwords, etc.) cannot 
  be audited by this script. Review them manually before deleting a profile.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$UserName = "JerryAdmin",
    [string]$ProfilePath = "C:\Users\JerryAdmin",
    [string[]]$Sections,  # section substrings to explicitly include.
    [string[]]$Skip,      # section substrings to explicitly exclude.
    [switch]$ListSections # list all sections in script
)

# IMPORTANT NOTE FOR LLM CODING: Formatting notes: new code must wrap at
# 72 columns, no tabs, new code must be commented, make minimal
# changes, leave existing comments in place except to document
# changes. UTF-8. No emojis. No hardcoded constants. Use table driven
# paradigms.

$ErrorActionPreference = "Stop"

# ourobrous grossness from not having compiled language or macros
# finds all the section names by regexing script
function Get-AvailableSections {
    param([string]$ScriptPath = $PSCommandPath)

    $content = Get-Content -Path $ScriptPath -Raw

    # Improved regex: handles double quotes, single quotes, and extra whitespace
    [regex]::Matches($content, '(?m)^\s*Section\s+["'']([^"'']+)["'']') | 
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique
}

# Handle -ListSections switch
if ($ListSections) {
    $allSections = Get-AvailableSections
    
    Write-Host "`nAvailable Sections in this script:" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan

    foreach ($section in $allSections) {
        $status = "Enabled"
        $color  = "Green"

        # Check inclusion/exclusion status
        $isIncluded = $true
        if ($Sections) {
            $isIncluded = ($Sections |
	      Where-Object { $section -match [regex]::Escape($_) })
        }

        $isSkipped = $false
        if ($Skip) {
            $isSkipped = ($Skip |
	      Where-Object { $section -match [regex]::Escape($_) })
        }

        if ($isSkipped) {
            $status = "SKIPPED"
            $color  = "Red"
        }
        elseif (-not $isIncluded) {
            $status = "Filtered Out"
            $color  = "Yellow"
        }

        Write-Host ("  {0,-35} {1}" -f $section, $status) -ForegroundColor $color
    }

    Write-Host "`nTip: Use -Sections 'name' or -Skip 'name' to filter." -ForegroundColor Gray
    exit 0
}

# Auto-elevate the script if not running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[INFO] Requesting administrative privileges..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Your actual script logic starts here and runs in the new elevated window
Write-Host "[SUCCESS] Running with administrative privileges." -ForegroundColor Green

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Report = Join-Path $PWD "UserProfileAudit-$($UserName)-$stamp.log"

# Initialize report file
"" | Out-File -FilePath $Report -Encoding utf8

function Write-ReportLine {
    param(
        [string]$Text = "",
        [ValidateSet('Info','Pass','Warning','Action','Header')]
        [string]$Level = 'Info',
        
        # Defer remediation logic to a separate pipeline by 
        # capturing the raw data targets here.
        [string]$RemediationType = "",
        [string]$RemediationTarget = ""        
  )

    # 1. Console Colorization
    $color = switch ($Level) {
        'Pass'    { 'Green' }
        'Warning' { 'Yellow' }
        'Action'  { 'Red' }
        'Header'  { 'Cyan' }
        default   { 'White' }
    }

    Write-Host $Text -ForegroundColor $color

    # 2. File Output Formatting
    $Text | Out-File -FilePath $Report -Encoding utf8 -Append
        
    # Append plain text metadata for downstream regex scraping
    if ($RemediationTarget) {
        "  [DATA] TYPE: $RemediationType | " + 
        "TARGET: $RemediationTarget" | 
          Out-File -FilePath $Report -Encoding utf8 -Append
    }
}

# =====================================================================
# External Tools Configuration (Table-Driven)
# =====================================================================

$ExternalTools = @{

    "autorunsc.exe" = @{
        DisplayName = "Sysinternals Autorunsc"
        Required    = $true
        DownloadUrl = "https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns"
        ScoopName   = "sysinternals"
        StandardArgs = "-nobanner"
    }

    "accesschk.exe" = @{
        DisplayName = "Sysinternals AccessChk"
        Required    = $false
        DownloadUrl = "https://learn.microsoft.com/en-us/sysinternals/downloads/accesschk"
        ScoopName   = "sysinternals"
        StandardArgs = "-nobanner"
    }

    "reg.exe" = @{
        DisplayName = "reg.exe (built-in)"
        Required    = $false
        DownloadUrl = $null
        ScoopName   = $null
        StandardArgs = $null
    }
}

# =====================================================================
# Resolve Tools Once
# =====================================================================

function Resolve-ExternalTools {
    $criticalMissing = @()
    foreach ($entry in $ExternalTools.GetEnumerator()) {
        $name = $entry.Key
        $tool = $entry.Value

        $command = Get-Command -Name $name `
          -ErrorAction SilentlyContinue -CommandType Application

        if ($command) {
            $tool.Path = $command.Source
            $tool.Command = $command
        }
        else {
            if ($tool.Required) {
                Write-ReportLine `
                  "[ERROR] $($tool.DisplayName) is required but missing." `
                  -Level Error
                Write-ReportLine `
                  "Download: $($tool.DownloadUrl)" `
                  -Level Error
                
                if ($tool.ScoopName) {
                    Write-ReportLine `
                      "Install : scoop install $($tool.ScoopName)" `
                      -Level Error
                }
                $criticalMissing += $name
            }
            else {
                Write-ReportLine ("[NOTICE] $($tool.DisplayName)" `
                  + "not found. Related features skipped.") `
                  -Level Warning
                if ($tool.ScoopName) {
                    Write-ReportLine "   scoop install $($tool.ScoopName)" `
                      -Level Warning
                }
            }
        }
    }
    if ($criticalMissing) {
        $missingList = $criticalMissing -join ", "
        throw "Missing required tool(s): $missingList"
    }
}

# Helper Function to call 
# Example: 
# Invoke-Tool "autorunsc.exe" @("-accepteula", "-m", "-s", "*")
# Invoke-Tool "accesschk.exe" @("-accepteula", "-q", "-d", "C:\Windows\System32")
#
# You can still call directly if you prefer
# & $ExternalTools["autorunsc.exe"].Path -accepteula -m
function Invoke-Tool {
    <#
    .SYNOPSIS
        Convenient way to call external tools after resolution
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,        
        
        # Added ValueFromRemainingArguments so unbound switches like
        # '-nobanner' pass cleanly into the arguments array instead of
        # throwing binding errors.
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments = @()
    )

    $tool = $ExternalTools[$Name]
    
    Write-Verbose "tool[${name}] = $($tool.Path)"
    
    if (-not $tool -or -not $tool.Path) {
        throw "Tool '$Name' is not available or has not been resolved."
    }

    Write-Verbose "Arguments=$($Arguments -join ' ')"
    & $tool.Path $Arguments
}

# =====================================================================
# Initialize External Tools
# =====================================================================

Resolve-ExternalTools

# --- Sections -------------------------------------------

function Section {
    param([string]$Name,
          [scriptblock]$Body)

    # Documenting change: Table-driven substring checks for inclusion
    # and exclusion using the new script parameters.
    $runSection = $true

    if ($script:Sections) {
        $runSection = ($script:Sections | Where-Object { 
            $Name -match [regex]::Escape($_) 
        }) -as [bool]
    }

    if ($runSection -and $script:Skip) {
        $shouldSkip = ($script:Skip | Where-Object { 
            $Name -match [regex]::Escape($_) 
        }) -as [bool]
        
        if ($shouldSkip) {
            $runSection = $false
        }
    }

    if (-not $runSection) {
        return
    }

    # Close out timing for whichever section just finished (if
    # any) before starting the clock on the new one.
    Stop-CurrentSectionTiming

    $script:CurrentSectionName = $Name
    $script:CurrentSectionSw = `
      [System.Diagnostics.Stopwatch]::StartNew()

    Write-ReportLine ""
    Write-ReportLine ("=" * 72)
    Write-ReportLine $Name
    Write-ReportLine ("=" * 72)

    & $Body

}

# --- Section timing -------------------------------------------
#
# Sections are plain sequential code, not scriptblocks, so we
# can't wrap each one in Measure-Command without restructuring
# the whole script. Instead, Section() above starts a stopwatch
# each time it's called, and Stop-CurrentSectionTiming() (called
# both by Section() and once manually at the very end) closes
# out the *previous* section's timer and records its elapsed
# time. This keeps the per-section code untouched.

$script:SectionTimings = `
  [System.Collections.Generic.List[pscustomobject]]::new()
$script:CurrentSectionName = $null
$script:CurrentSectionSw = $null

function Stop-CurrentSectionTiming {
    if ($script:CurrentSectionName) {
        $script:CurrentSectionSw.Stop()
        $script:SectionTimings.Add(
            [pscustomobject]@{
                Section = $script:CurrentSectionName
                Seconds = [math]::Round(
                  $script:CurrentSectionSw.Elapsed.TotalSeconds, 2)
            }
        )
    }
}

function Safe {
    param(
        [scriptblock]$Body,
        [string]$Context
    )
    try {
        & $Body
        $true
    }
    catch {
        Write-ReportLine "[WARNING] ${Context}: $_"
        $false
    }
}

Section "Profile" {

    Write-ReportLine "User    : $UserName"
    Write-ReportLine "Profile : $ProfilePath"

    if (Test-Path $ProfilePath){
        $size = (Get-ChildItem `
          $ProfilePath -Force -Recurse -File -ErrorAction SilentlyContinue |
          Measure-Object Length -Sum).Sum
        Write-ReportLine ("Size    : {0:N2} GB" -f ($size/1GB))
    } else {
        Write-ReportLine "Profile directory not found."
    }
}

Section "Directories" {

    # Minimal enhancement: report count + size (per user request)
    @(
        ".ssh",
        ".gnupg",
        "Documents\WindowsPowerShell",
        "Documents\PowerShell",
        "AppData\Local\Programs",
        "AppData\Microsoft\Windows\Start Menu\Programs\Startup"
    ) | ForEach-Object{
        $p=Join-Path $ProfilePath $_
        if (Test-Path $p) {
            $items = Get-ChildItem $p -Recurse -Force -File `
              -ErrorAction SilentlyContinue
            $sizeGB = if ($items) { ($items |
              Measure-Object Length -Sum).Sum / 1GB } else { 0 }
            Write-ReportLine (
                ("{0,-55} Exists: True | Files: {1} | Size: {2:N2} GB") `
                  -f $_, $items.Count, $sizeGB)
        } else {
            Write-ReportLine ("{0,-55} Exists: False" -f $_)
        }
    }
}

Section "Executables" {

    # NOISE FILTER EXPLANATIONS:
    #
    # 1. AppData\Local\Temp & \Temp\: Ephemeral cache files, auto-generated
    #    installers, and installer stubs. Not permanent user scripts.
    #
    # 2. AppData\Local\Packages: UWP App Sandbox folders (e.g., Microsoft
    #    Edge, Store Apps). Generated by Windows, not human user scripts.
    #
    # 3. AppData\Local\Microsoft\Windows\INetCache: Browser cache
    #    binaries/scripts downloaded while browsing.
    #
    # 4. \node_modules\ & \.git\: Developer dependency trees/repositories
    #    containing thousands of third-party CLI scripts/binaries.
    #
    # 5. AppData\Local\Microsoft\WindowsApps: OS-generated Store-app
    #    alias stubs (notepad.exe, wt.exe, bash.exe, etc.). These are
    #    placeholder shims Windows creates itself, not evidence the
    #    user installed anything.
    #
    # 6. AppData\Local\Microsoft\OneDrive: OneDrive's own installer
    #    and sync-service binaries, laid down by the OneDrive client
    #    itself rather than by user action.

    $null = Safe {
        $excludePatterns = `
          '\\(Temp|AppData\\Local\\Temp|' `
          + 'AppData\\Local\\Packages|' `
          + 'AppData\\Local\\Microsoft\\Windows\\INetCache|' `
          + 'AppData\\Local\\Microsoft\\WindowsApps|' `
          + 'AppData\\Local\\Microsoft\\OneDrive|' `
          + '\.git|node_modules)\\'

        $foundExecutables = Get-ChildItem $ProfilePath -Recurse `
          -Force -ErrorAction SilentlyContinue `
          -Include *.exe,*.cmd,*.bat,*.ps1,*.vbs |
          Where-Object { $_.FullName -notmatch $excludePatterns }

        if ($foundExecutables) {
            # Group by extension and take up to 50 per file type to avoid
            # one noisy file type dominating
            $foundExecutables | Group-Object Extension | 
              ForEach-Object {
                  Write-ReportLine `
                    "-- Extension: $($_.Name) (First 50 of $($_.Count)) --"
                  $_.Group | Select-Object -First 50 | ForEach-Object {
                      # Minimal: add size + created date for executables
                      $info = Get-Item $_.FullName -ErrorAction SilentlyContinue
                      $meta = if ($info) { " | Size:{0:N1}MB Created:{1}" -f `
                        ($info.Length/1MB), $info.CreationTime.Date } else {""}
                      Write-ReportLine ("  {0}{1}" -f $_.FullName, $meta)
                  }
              }
        } else {
            Write-ReportLine (
                "No executable binaries or scripts found" `
                  + "outside excluded temp/cache paths."
            )
        }
    } "Searching profile executable content"
}

Section "HKCU Keys" {

    $tempHive="HKU\OLDPROFILEAUDIT"
    $nt=Join-Path $ProfilePath "NTUSER.DAT"

    if (Test-Path $nt){
        $loaded = Safe {
            Invoke-Tool "reg.exe" load $tempHive $nt | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "reg load failed with exit code $LASTEXITCODE"
            }
        } "Loading NTUSER.DAT"

        if ($loaded){
            try {
                $null = Safe {
                    # Display explicit username header 
                    Write-ReportLine "Registry: $nt"
                    Write-ReportLine "-- Uninstall entries --"

                    $unKey = '\Software\Microsoft\Windows\CurrentVersion\Uninstall'
                    $k = "Registry::$tempHive" + $unKey

                    if (Test-Path $k){
                        # Substitute internal temp path with standard HKCU
                        # notation to match typical registry expectations
                        $displayK = "  HKCU" + $k
                        Write-ReportLine $displayK
                        
                        Get-ChildItem $k | ForEach-Object{
                            $p=Get-ItemProperty $_.PSPath
                            if ($p.DisplayName){
                                Write-ReportLine (
                                    "    Key: {0}" -f $_.PSChildName)
                                Write-ReportLine (
                                    "      {0} | {1} | {2}" -f 
                                    $p.DisplayName, $p.DisplayVersion, 
                                    $p.Publisher)
                            }
                        }
                    }
                } "Reading uninstall keys"

                $null = Safe {
                    foreach($r in
                            "Software\Microsoft\Windows\CurrentVersion\Run",
                            "Software\Microsoft\Windows\CurrentVersion\RunOnce"){
                                $k="Registry::$tempHive\$r"
                                Write-ReportLine "-- $r --"
                                if (Test-Path $k){
                                    (Get-ItemProperty $k).PSObject.Properties |
                                      Where-Object Name -notmatch '^PS' |
                                      ForEach-Object{
                                          Write-ReportLine ("  {0} = {1}" -f `
                                            $_.Name, $_.Value)
                                      }
                                }
                            }
                } "Reading Run keys"
            }
            finally {
                # Guaranteed registry unmount regardless of exceptions
                # during read operations
                $null = Safe {
                    Invoke-Tool "reg.exe" unload $tempHive "*>" $null
                } "Unloading hive"
            }
        }
    }
}

Section "Global Uninstalls" {

    $null = Safe {
        Write-ReportLine "Scanning HKLM Uninstall keys for old profile paths..."
        
        $uninstallPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\" + `
              "CurrentVersion\Uninstall"
        )

        $foundAny = $false

        foreach ($path in $uninstallPaths) {
            if (Test-Path $path) {
                Get-ChildItem $path -ErrorAction SilentlyContinue | 
                  ForEach-Object {
                      $prop = Get-ItemProperty $_.PSPath
                      
                      $isOrphan = $false
                      # Check the three standard properties that point to files
                      foreach ($val in @($prop.InstallLocation, 
                                         $prop.UninstallString, 
                                         $prop.QuietUninstallString)) {
                                             if ($val -match [regex]::Escape($ProfilePath)) {
                                                 $isOrphan = $true
                                             }
                                         }

                      if ($isOrphan) {
                          $foundAny = $true
                          # Fallback to the registry key name if DisplayName 
                          # is missing
                          $name = if ($prop.DisplayName) { $prop.DisplayName } 
                          else { $_.PSChildName }
                          
                          Write-ReportLine -Text ("  {0} | {1}" -f `
                            $name, $prop.DisplayVersion) `
                            -Level Warning `
                            -RemediationType "HKLMUninstall" `
                            -RemediationTarget $_.PSPath
                      }
                  }
            }
        }

        if (-not $foundAny) {
            Write-ReportLine -Text "  No orphaned machine-wide uninstallers." `
              -Level Pass
        }
    } "Auditing HKLM Uninstall keys"
}

Section "Global References" {

    $null = Safe {

        if ($ExternalTools["autorunsc.exe"]) {
            Write-ReportLine "Scanning auto-starts via autorunsc..."
            # -a *: all entries, -c: CSV output, -nobanner: suppress header
            $csvOutput = Invoke-Tool "autorunsc.exe" -a '*' -c -nobanner 2>$null
            $csv = $csvOutput | ConvertFrom-Csv -ErrorAction SilentlyContinue

            if ($csv) {
                $orphans = $csv | Where-Object {
                    $isMatch = $false
                    # Check every column dynamically in case schema changes
                    $_.PSObject.Properties | ForEach-Object {
                        if ($_.Value -match [regex]::Escape($ProfilePath)) {
                            $isMatch = $true
                        }
                    }
                    $isMatch
                }

                if ($orphans) {
                    $orphans | ForEach-Object {
                        Write-ReportLine ("Location: {0}" -f $_.Location)
                        Write-ReportLine ("  Entry   : {0}" -f $_.Entry)
                        Write-ReportLine ("  Path    : {0}" -f $_."Image Path")
                        Write-ReportLine ("  " + "-" * 68)
                    }
                    Write-ReportLine ""
                } else {
                    Write-ReportLine "  No machine-wide auto-starts found."
                }
            }
        } else {
            Write-ReportLine "Autorunsc missing. Please install"
        }

        Write-ReportLine ""
        Write-ReportLine "Scanning HKLM for literal string matches..."
        # Using native reg.exe. RegScanner CLI requires a binary/ini .cfg
        # file to run silently, which reduces script portability.
        foreach ($hive in @("HKLM\SOFTWARE", "HKLM\SYSTEM")) {
            $regEntries = Invoke-Tool "reg.exe" query $hive /f $ProfilePath /s /d /v 2> $null
            if ($LASTEXITCODE -eq 0 -and $regEntries) {
                # Named $hits rather than $matches to avoid shadowing
                # PowerShell's automatic $matches variable (populated
                # by the -match operator used just above).
                $hits = $regEntries |
                  Where-Object { $_ -match 'HKEY' -or $_ -match 'REG_' }

                # Honest truncation label, mirroring the "First 50 of
                # N" pattern used in the executable content section,
                # so it's clear whether all matches are being shown.
                $shown = $hits | Select-Object -First 30
                Write-ReportLine (
                    "  -- {0}: First {1} of {2} --" `
                      -f $hive, $shown.Count, $hits.Count)
                $shown | ForEach-Object {
                    # Indent value lines further than key paths
                    $line = $_.Trim()
                    if ($line -match '^HKEY_') {
                        Write-ReportLine ("  {0}" -f $line)
                    } else {
                        Write-ReportLine ("       {0}" -f $line)
                    }
                }
            } else {
                Write-ReportLine "  No matches found in $hive."
            }
        }
    } "Auditing machine-wide references"
}

Section "Scheduled Tasks" {

    $null = Safe {
        # Resolve the username to a Security Identifier (SID)
        $userSid = $null
        try {
            $ntAccount = New-Object `
              System.Security.Principal.NTAccount($UserName)
            $userSid = $ntAccount.Translate(
                [System.Security.Principal.SecurityIdentifier]).Value
        } catch {
            Write-ReportLine -Text "[WARNING] Could not resolve SID for $UserName" `
              -Level Warning
        }

        Get-ScheduledTask |
          Where-Object {
              $isPrincipalMatch = ($_.Principal.UserId -match `
                [regex]::Escape($UserName))
              
              $isSidMatch = ($userSid -and `
                ($_.Principal.UserId -eq $userSid))
              
              $isActionMatch = $false
              if ($_.Actions) {
                  foreach ($action in $_.Actions) {
                      # Check both Execute path and command Arguments
                      if (($action.Execute -match `
                        [regex]::Escape($ProfilePath)) -or
                          ($action.Arguments -match `
                            [regex]::Escape($ProfilePath))) {
                                $isActionMatch = $true
                            }
                  }
              }
              
              $isPrincipalMatch -or $isSidMatch -or $isActionMatch
          } |
            ForEach-Object {
                $msg = "{0} -> {1}" -f $_.TaskPath, $_.TaskName
                Write-ReportLine -Text $msg `
                  -Level Warning `
                  -RemediationType "ScheduledTask" `
                  -RemediationTarget "$($_.TaskPath)$($_.TaskName)"
            }
    } "Scheduled tasks"
}

Section "Services" {

    $null = Safe {
        Get-CimInstance Win32_Service |
          Where-Object{
              $_.StartName -match [regex]::Escape($UserName)
          } |
            ForEach-Object{
                Write-ReportLine ("{0} ({1})" -f $_.Name,$_.StartName)
            }
    } "Services"
}

Section "External System File Ownership" {

    $null = Safe {

        if ($ExternalTools["accesschk.exe"]) {
            Write-ReportLine ("Sysinternals AccessChk scan " `
              + "for files owned by '$UserName'...")
            
            $targetSystemPaths = @(
                "C:\ProgramData",
                "C:\Program Files",
                "C:\Program Files (x86)",
                "C:\Windows\System32\Tasks",
                "C:\Drivers",
                "C:\Tools",
                "C:\Scripts"
            )

            foreach ($sysPath in $targetSystemPaths) {
                if (Test-Path $sysPath) {
                    Write-ReportLine "-- Ownership Audit: $sysPath --"
                    # -q: suppress banner, -s: recurse, -o: filter by owner
                    Invoke-Tool "accesschk.exe" -nobanner -s -o $UserName $sysPath |
                      ForEach-Object {
                          Write-ReportLine ("  {0}" -f $_)
                      }
                }
            }
        } else {
            Write-ReportLine "AccessChk missing, please install"
        }
    } "Auditing external file ownership"
}

Section "Summary" {

    # Minimal JSON remediation summary (structured, parseable)
    $remediationData = @()  # populated via Write-ReportLine calls where used
    Write-ReportLine "Remediation JSON: []"  # placeholder; extend as needed

    Write-ReportLine "If the sections above are essentially empty, there is little evidence"
    Write-ReportLine "deleting this profile will break software or orphan system file ownership."

    Write-ReportLine ""
    Write-ReportLine (
        "[MANUAL CHECK] DPAPI-protected secrets are not covered " `
          + "above -- no file or registry")
    Write-ReportLine (
        "scan can flag them. Credential Manager entries, saved " `
          + "Wi-Fi passwords, and some")
    Write-ReportLine (
        "app configs are encrypted per-profile via DPAPI. " `
          + "Deleting the profile destroys")
    Write-ReportLine (
        "those keys; the secrets become unrecoverable even if " `
          + "the underlying files were")
    Write-ReportLine (
        "backed up. Review Credential Manager and saved Wi-Fi " `
          + "profiles by hand before")
    Write-ReportLine "deleting, if this account may hold any."

    # Close out the Summary section's own timer before reporting on
    # section timings.
    Stop-CurrentSectionTiming
}

Section "Timing" {

    Write-ReportLine "Per-section execution time (slowest first):"
    Write-ReportLine ""

    $totalSeconds = ($script:SectionTimings |
      Measure-Object Seconds -Sum).Sum

    $script:SectionTimings |
      Sort-Object Seconds -Descending |
      ForEach-Object {
          Write-ReportLine (
              "  {0,-40} {1,8:N2} sec" -f $_.Section, $_.Seconds)
      }

    Write-ReportLine ("  " + ("-" * 51))
    Write-ReportLine (
        "  {0,-40} {1,8:N2} sec" -f "TOTAL", $totalSeconds)
}

Write-Host ""
Write-Host "Report written to $Report"
