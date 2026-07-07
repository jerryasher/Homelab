
<#
.SYNOPSIS
    Extracts embedded scripts from handbook appendix files.
.DESCRIPTION
    Scans one or more appendix Markdown files for the
    "#### FILE: <filename>" marker convention and writes
    the fenced code block that immediately follows each
    marker out to disk as its own file. Supports scanning
    an explicit list of filenames/wildcards, an existing
    Index.md (via -IndexFile) to derive the file list, or
    both combined.

    Running this file directly performs the extraction;
    the Export-AppendixScript function inside it can also
    be dot-sourced and called again later in the same
    session.

    Extracted files are written UTF-8 without a byte order
    mark and with LF line endings regardless of platform,
    so a script extracted on Windows diffs cleanly against
    one extracted on Linux. Each extracted file's full
    resolved path is written to output as confirmation.
.PARAMETER Path
    Ordered appendix filenames / wildcard patterns to scan
    for embedded scripts.
.PARAMETER IndexFile
    Path to an Index.md (or similarly formatted file) whose
    bulleted entries name the appendix files to scan. Read
    first and combined with -Path, duplicates removed.
.PARAMETER Directory
    Directory containing the appendix files. Defaults to
    the current directory.
.PARAMETER OutputDirectory
    Directory extracted scripts are written to. Defaults to
    the current directory. Created if it does not exist.
.PARAMETER Force
    Overwrite an extracted file if one already exists at the
    destination path. Without -Force, existing files are
    skipped with a warning.
.PARAMETER Version
    Print the script version and exit.
.PARAMETER Help
    Show full help (equivalent to Get-Help -Full) and exit.
.EXAMPLE
    .\Export-AppendixScript.ps1 `
        'App 10 - Recapping LLM Chats into Appendices.md' `
        -Directory 'C:\me\workspace\handbook' `
        -OutputDirectory 'C:\me\workspace\handbook\scripts'

    Extracts every embedded script found in the one named
    appendix.
.EXAMPLE
    .\Export-AppendixScript.ps1 `
        -IndexFile 'C:\me\workspace\handbook\Index.md' `
        -Directory 'C:\me\workspace\handbook' `
        -OutputDirectory 'C:\me\workspace\handbook\scripts' `
        -WhatIf

    Previews extracting scripts from every appendix listed
    in Index.md, without writing anything.
.NOTES
    Version: 1.0.0
#>

[CmdletBinding(SupportsShouldProcess = $true,
    ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false, Position = 0,
        ValueFromRemainingArguments)]
    [string[]] $Path = @(),

    [string] $IndexFile,

    [string] $Directory = (Get-Location).Path,

    [string] $OutputDirectory = (Get-Location).Path,

    [Switch] $Force,

    [Switch] $Version,

    [Switch] $Help
)

# --- Script Metadata --------------------------------
$ScriptVersion = '1.0.0'

if ($Version) {
    Write-Host "Export-AppendixScript.ps1 version $ScriptVersion"
    return
}

if ($Help) {
    Get-Help -Name $PSCommandPath -Full
    return
}

function Export-AppendixScript {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $false, Position = 0,
            ValueFromRemainingArguments)]
        [string[]] $Path = @(),

        [string] $IndexFile,

        [string] $Directory = (Get-Location).Path,

        [string] $OutputDirectory = (Get-Location).Path,

        [Switch] $Force
    )

    # --- Constants & Patterns ------------------------
    $IndexLineRx = '^\s*[\*\-\+]\s*\*\*(.*?)\*\*'
    $FileMarkerRx = '^####\s*FILE:\s*(.+?)\s*$'
    $FenceOpenRx = '^```(\S*)\s*$'
    $FenceCloseRx = '^```\s*$'
    $LineEnding = "`n"
    $Utf8NoBom = New-Object System.Text.UTF8Encoding(
        $false)

    # --- Stage 1: Build Ordered Candidate List -------
    $rawQueue =
        New-Object System.Collections.Generic.List[string]

    if ($IndexFile) {
        if (Test-Path $IndexFile) {
            Write-Verbose ("Reading appendix list " +
                "from: $IndexFile")
            foreach ($line in (Get-Content $IndexFile)) {
                if ($line -match $IndexLineRx) {
                    $rawQueue.Add($Matches[1])
                }
            }
        }
        else {
            Write-Warning "IndexFile not found: $IndexFile"
        }
    }

    foreach ($p in $Path) {
        $rawQueue.Add($p)
    }

    # --- Stage 2: Resolve, Expand Wildcards, Dedup ---
    $seen = New-Object `
        System.Collections.Generic.HashSet[string](
            [System.StringComparer]::OrdinalIgnoreCase)
    $resolvedFiles =
        New-Object System.Collections.Generic.List[string]

    foreach ($item in $rawQueue) {
        $found = if ($item -match '[\*\?]') {
            Get-ChildItem `
                -Path (Join-Path $Directory $item) `
                -File -ErrorAction SilentlyContinue |
                Sort-Object Name
        }
        else {
            $full = if (Split-Path $item -Parent) {
                $item
            }
            else {
                Join-Path $Directory $item
            }
            if (Test-Path $full) {
                Get-Item $full
            }
            else {
                Write-Warning "File not found: $item"
                $null
            }
        }

        foreach ($f in $found) {
            if (-not $f) { continue }
            $fullPath = (Resolve-Path $f.FullName).Path
            if ($seen.Add($fullPath)) {
                $resolvedFiles.Add($fullPath)
            }
        }
    }

    # --- Stage 3: Ensure Output Directory Exists -----
    if (-not (Test-Path $OutputDirectory)) {
        if ($PSCmdlet.ShouldProcess($OutputDirectory,
                'Create output directory')) {
            New-Item -Path $OutputDirectory `
                -ItemType Directory -Force | Out-Null
        }
    }

    # --- Stage 4: Scan Each File For FILE Markers ----
    $extractedCount = 0

    foreach ($appendixPath in $resolvedFiles) {
        $lines = Get-Content -Path $appendixPath
        $leafName = Split-Path $appendixPath -Leaf
        $i = 0

        while ($i -lt $lines.Count) {
            if ($lines[$i].Trim() -notmatch $FileMarkerRx) {
                $i++
                continue
            }

            $scriptName = $Matches[1]
            $j = $i + 1

            # Skip blank lines between the marker and
            # the fenced code block that must follow it.
            while ($j -lt $lines.Count -and
                    $lines[$j].Trim() -eq '') {
                $j++
            }

            if ($j -ge $lines.Count -or
                    $lines[$j] -notmatch $FenceOpenRx) {
                Write-Warning ("FILE marker for " +
                    "'$scriptName' in '$leafName' is " +
                    "not immediately followed by a " +
                    "fenced code block -- skipping.")
                $i++
                continue
            }

            $j++
            $codeLines = New-Object `
                System.Collections.Generic.List[string]

            while ($j -lt $lines.Count -and
                    $lines[$j] -notmatch $FenceCloseRx) {
                $codeLines.Add($lines[$j])
                $j++
            }

            $destPath = [System.IO.Path]::GetFullPath(
                (Join-Path $OutputDirectory $scriptName))

            if ((Test-Path $destPath) -and -not $Force) {
                Write-Warning ("'$destPath' already " +
                    "exists -- use -Force to " +
                    "overwrite. Skipping.")
                $i = $j + 1
                continue
            }

            if ($PSCmdlet.ShouldProcess($destPath,
                    'Write extracted script')) {
                $fileText = ($codeLines -join
                    $LineEnding) + $LineEnding
                [System.IO.File]::WriteAllText(
                    $destPath, $fileText, $Utf8NoBom)
                Write-Host ("Extracted $destPath " +
                    "from $leafName")
                $extractedCount++
            }

            $i = $j + 1
        }
    }

    Write-Host ("Extracted $extractedCount " +
        "script(s) total.")
}

Export-AppendixScript @PSBoundParameters
