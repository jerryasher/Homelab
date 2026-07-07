
<#
.SYNOPSIS
    Regenerates Index.md from handbook appendix files.
.DESCRIPTION
    Accepts an ordered list of filenames and/or wildcard
    patterns, or parses an existing Index.md to derive a
    baseline file list. Processes items in original order,
    expands wildcards hierarchically, deduplicates the
    combined list, then removes excluded files, and writes
    one bulleted Index.md entry per remaining file.

    Creates OutFile if it does not exist, or overwrites it
    if it does -- this is a create-or-replace operation, not
    an update-only one.

    Running this file directly performs the operation; the
    Set-Index function inside it can also be dot-sourced and
    called again later in the same session.
.PARAMETER Path
    Ordered filenames / wildcard patterns to combine or
    process.
.PARAMETER Update
    Switch indicating that the existing index at -OutFile
    should be read first to derive a baseline file list,
    before combining with -Path.
.PARAMETER Exclude
    Filenames to remove from the final collection after
    deduplication, before metadata is parsed.
.PARAMETER Directory
    Directory to search. Defaults to current directory.
.PARAMETER OutFile
    Output index path. Defaults to .\Index.md
.PARAMETER Version
    Print the script version and exit.
.PARAMETER Help
    Show full help (equivalent to Get-Help -Full) and exit.
.EXAMPLE
    .\Set-Index.ps1 README.md, Guidelines.md, App*.md `
        -Directory 'C:\me\workspace\handbook' `
        -OutFile 'C:\me\workspace\handbook\Index.md'

    Builds a fresh index from an explicit file list plus a
    wildcard, with the wildcard matches sorted by the
    App N.X.Y hierarchy.
.EXAMPLE
    .\Set-Index.ps1 -Update -Path 'App 3.A - Draft System.md' `
        -Exclude 'App 1.B - Old Spec.md' `
        -Directory 'C:\me\workspace\handbook' `
        -OutFile 'C:\me\workspace\handbook\Index.md' `
        -WhatIf

    Previews reading the current Index.md, appending a new
    file, and dropping a decommissioned one, without writing
    anything.
.NOTES
    Version: 1.0.0
#>

[CmdletBinding(SupportsShouldProcess = $true,
    ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false, Position = 0,
        ValueFromRemainingArguments)]
    [string[]] $Path = @(),

    [Switch] $Update,

    [string[]] $Exclude = @(),

    [string] $Directory = (Get-Location).Path,

    [string] $OutFile = (Join-Path
        (Get-Location).Path 'Index.md'),

    [Switch] $Version,

    [Switch] $Help
)

# --- Script Metadata --------------------------------
$ScriptVersion = '1.0.0'

if ($Version) {
    Write-Host "Set-Index.ps1 version $ScriptVersion"
    return
}

if ($Help) {
    Get-Help -Name $PSCommandPath -Full
    return
}

function Set-Index {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $false, Position = 0,
            ValueFromRemainingArguments)]
        [string[]] $Path = @(),

        [Switch] $Update,

        [string[]] $Exclude = @(),

        [string] $Directory = (Get-Location).Path,

        [string] $OutFile = (Join-Path
            (Get-Location).Path 'Index.md')
    )

    # --- Constants & Patterns ------------------------
    $SummaryHeader = '## SUMMARY'
    $TagsHeader = '#### TAGS'
    $MarkdownHeaderMarker = '#'
    $AppNumberRx =
        '^App\s+([0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)\s*-'
    $IndexLineRx = '^\s*[\*\-\+]\s*\*\*(.*?)\*\*'
    $UnnumberedSortPrefix = 'ZZZZ'
    $OutputBulletMarker = '*'
    $IndexDateFormat = 'yyyy-MM-dd'
    $IndexEncoding = 'UTF8'

    function Get-AppSortKey {
        param([string] $FileName)

        $m = [regex]::Match($FileName, $AppNumberRx)

        if (-not $m.Success) {
            # Files with no "App N - Title" pattern sort
            # after all numbered appendices.
            return "$UnnumberedSortPrefix|$FileName"
        }

        $segments = $m.Groups[1].Value -split '\.'
        $padded = foreach ($seg in $segments) {
            if ($seg -match '^\d+$') {
                $seg.PadLeft(4, '0')
            }
            else {
                $seg.ToUpperInvariant()
            }
        }
        return ($padded -join '.')
    }

    # Returns the first non-blank line after a header
    # whose trimmed text equals $HeaderText exactly.
    # Stops at the next line starting with "#", at any
    # hash depth. Plain text only, no regex -- this
    # relies entirely on the fixed TITLE / WRITTEN /
    # SUMMARY / TAGS prologue that every appendix is
    # assumed to start with.
    function Get-TextAfterHeader {
        param(
            [string[]] $Lines,
            [string]   $HeaderText
        )

        $collecting = $false
        foreach ($line in $Lines) {
            if (-not $collecting) {
                if ($line.Trim() -eq $HeaderText) {
                    $collecting = $true
                }
                continue
            }

            if ($line.TrimStart().StartsWith(
                    $MarkdownHeaderMarker)) {
                break
            }

            $trimmed = $line.Trim()
            if ($trimmed -ne '') {
                return $trimmed
            }
        }

        return $null
    }

    function Get-AppendixMetadata {
        param([string] $FilePath)

        $lines = Get-Content -Path $FilePath
        $fileName = Split-Path $FilePath -Leaf

        $summary = Get-TextAfterHeader -Lines $lines `
            -HeaderText $SummaryHeader
        $tags = Get-TextAfterHeader -Lines $lines `
            -HeaderText $TagsHeader

        if (-not $summary -and -not $tags) {
            Write-Warning ("No $SummaryHeader or " +
                "$TagsHeader section found in " +
                "'$fileName' -- adding to index by " +
                "filename only.")
        }

        [PSCustomObject]@{
            FileName = $fileName
            Summary  = $summary
            Tags     = $tags
        }
    }

    # --- Stage 1: Build Initial File Stream ----------
    $rawQueue =
        New-Object System.Collections.Generic.List[string]

    # If Update is specified, seed our queue from the
    # target file list first.
    if ($Update) {
        if (Test-Path $OutFile) {
            Write-Verbose ("Reading baseline files " +
                "from existing index: $OutFile")
            foreach ($line in (Get-Content $OutFile)) {
                if ($line -match $IndexLineRx) {
                    $rawQueue.Add($Matches[1])
                }
            }
        }
        else {
            Write-Warning ("Update switch used, but " +
                "target index file does not exist " +
                "at: $OutFile")
        }
    }

    # Append explicitly passed path items.
    foreach ($p in $Path) {
        $rawQueue.Add($p)
    }

    # --- Stage 2: Resolve, Expand and Sort Wildcards --
    $expandedQueue =
        New-Object System.Collections.Generic.List[string]

    foreach ($item in $rawQueue) {
        if ($item -match '[\*\?]') {
            $found = Get-ChildItem `
                -Path (Join-Path $Directory $item) `
                -File -ErrorAction SilentlyContinue
            $sorted = $found |
                Sort-Object { Get-AppSortKey $_.Name }
            foreach ($f in $sorted) {
                $expandedQueue.Add($f.FullName)
            }
        }
        else {
            # Could be an item found in index
            # extraction (just filename) or a full
            # literal path.
            $full = if (Split-Path $item -Parent) {
                $item
            }
            else {
                Join-Path $Directory $item
            }
            if (Test-Path $full) {
                $expandedQueue.Add(
                    (Resolve-Path $full).Path)
            }
            else {
                Write-Warning ("File not found or " +
                    "unresolvable: $item")
            }
        }
    }

    # --- Stage 3: Deduplicate, Then Filter Exclusions -
    $seen = New-Object `
        System.Collections.Generic.HashSet[string](
            [System.StringComparer]::OrdinalIgnoreCase)
    $finalFiles =
        New-Object System.Collections.Generic.List[string]

    # Normalize exclusions into a list of plain
    # filenames for fast lookup.
    $exclusionSet = New-Object `
        System.Collections.Generic.HashSet[string](
            [System.StringComparer]::OrdinalIgnoreCase)
    foreach ($exc in $Exclude) {
        if ($exc) {
            [void]$exclusionSet.Add(
                (Split-Path $exc -Leaf))
        }
    }

    foreach ($pathString in $expandedQueue) {
        # Dedup first: a path already seen is dropped
        # regardless of whether it's also excluded.
        if (-not $seen.Add($pathString)) {
            Write-Verbose "Skipping duplicate: $pathString"
            continue
        }

        $leafName = Split-Path $pathString -Leaf
        if ($exclusionSet.Contains($leafName)) {
            Write-Verbose ("Excluding file matching " +
                "rule: $leafName")
            continue
        }

        $finalFiles.Add($pathString)
    }

    # --- Stage 4: Generate Output Index.md -----------
    $lines =
        New-Object System.Collections.Generic.List[string]
    $lines.Add('# Index')
    $lines.Add('')
    $lines.Add(
        "Generated: $(Get-Date -Format $IndexDateFormat)")
    $lines.Add('')

    foreach ($file in $finalFiles) {
        $meta = Get-AppendixMetadata -FilePath $file

        $line = "$OutputBulletMarker **$($meta.FileName)**"
        if ($meta.Summary) {
            $line += " — $($meta.Summary)"
        }
        $lines.Add($line)

        if ($meta.Tags) {
            $lines.Add("  Tags: $($meta.Tags)")
        }
    }

    if ($PSCmdlet.ShouldProcess($OutFile,
            "Write $($finalFiles.Count) index entries")) {
        $lines | Set-Content -Path $OutFile `
            -Encoding $IndexEncoding
        Write-Host ("Wrote $($finalFiles.Count) " +
            "entries to $OutFile")
    }
}

Set-Index @PSBoundParameters
