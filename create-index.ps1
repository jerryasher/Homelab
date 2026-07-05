function Create-Index {
    <#
    .SYNOPSIS
        Regenerates Index.md from handbook appendix files.

    .DESCRIPTION
        Accepts an ordered list of filenames and/or
        wildcard patterns, e.g.:
            Create-Index README.md, Guidelines.md, App*.md
        Literal filenames appear in the order given.
        Wildcard matches are expanded and sorted by the
        "App N.X.Y" numbering in each filename before
        being inserted. Each file is scanned for a
        "## SUMMARY" section and a "## TAGS" line, which
        become one Markdown bullet per file.

    .PARAMETER Path
        Ordered filenames / wildcard patterns.

    .PARAMETER Directory
        Directory to search. Defaults to current directory.

    .PARAMETER OutFile
        Output index path. Defaults to .\Index.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0,
            ValueFromRemainingArguments)]
        [string[]] $Path,

        [string] $Directory = (Get-Location).Path,

        [string] $OutFile = (Join-Path `
            (Get-Location).Path 'Index.md')
    )

    # --- Constants ------------------------------------
    $SummaryHeader = '## SUMMARY'
    $TagsHeader    = '## TAGS'
    $HeaderPattern = '^##\s'
    $AppNumberRx   =
        '^App\s+([0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)\s*-'
    $MultilineOpt  =
        [System.Text.RegularExpressions.RegexOptions]::Multiline

    function Get-AppSortKey {
        param([string] $FileName)

        $m = [regex]::Match($FileName, $AppNumberRx)

        if (-not $m.Success) {
            # Files with no "App N - Title" pattern sort
            # after all numbered appendices.
            return "ZZZZ|$FileName"
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

    function Get-AppendixMetadata {
        param([string] $FilePath)

        $text = Get-Content -Raw -Path $FilePath

        $summary = $null
        $sIdx = $text.IndexOf($SummaryHeader)
        if ($sIdx -ge 0) {
            $rest = $text.Substring(
                $sIdx + $SummaryHeader.Length)
            $nextHeader = [regex]::Match(
                $rest, $HeaderPattern, $MultilineOpt)
            $body = if ($nextHeader.Success) {
                $rest.Substring(0, $nextHeader.Index)
            }
            else {
                $rest
            }
            $summary = ($body -split "`n" |
                Where-Object { $_.Trim() -ne '' } |
                Select-Object -First 1).Trim()
        }

        $tags = $null
        $tIdx = $text.IndexOf($TagsHeader)
        if ($tIdx -ge 0) {
            $rest = $text.Substring(
                $tIdx + $TagsHeader.Length)
            $tags = ($rest -split "`n" |
                Where-Object { $_.Trim() -ne '' } |
                Select-Object -First 1).Trim()
        }

        [PSCustomObject]@{
            FileName = Split-Path $FilePath -Leaf
            Summary  = $summary
            Tags     = $tags
        }
    }

    # --- Resolve ordered file list ---------------------
    $resolved = New-Object `
        System.Collections.Generic.List[string]

    foreach ($p in $Path) {
        if ($p -match '[\*\?]') {
            $found = Get-ChildItem `
                -Path (Join-Path $Directory $p) `
                -File -ErrorAction SilentlyContinue

            $sorted = $found |
                Sort-Object { Get-AppSortKey $_.Name }

            foreach ($f in $sorted) {
                $resolved.Add($f.FullName)
            }
        }
        else {
            $full = Join-Path $Directory $p
            if (Test-Path $full) {
                $resolved.Add(
                    (Resolve-Path $full).Path)
            }
            else {
                Write-Warning "Not found: $p"
            }
        }
    }

    # --- Build Index.md ---------------------------------
    $lines = New-Object `
        System.Collections.Generic.List[string]
    $lines.Add('# Index')
    $lines.Add('')
    $lines.Add(
        "Generated: $(Get-Date -Format 'yyyy-MM-dd')")
    $lines.Add('')

    foreach ($file in $resolved) {
        $meta = Get-AppendixMetadata -FilePath $file

        $line = "- **$($meta.FileName)**"
        if ($meta.Summary) {
            $line += " — $($meta.Summary)"
        }
        $lines.Add($line)

        if ($meta.Tags) {
            $lines.Add("  Tags: $($meta.Tags)")
        }
    }

    $lines | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host `
        "Wrote $($resolved.Count) entries to $OutFile"
}
