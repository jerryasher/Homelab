# App 10 - Recapping LLM Chats into Appendices

#### WRITTEN: 2026 July, 05

## SUMMARY

This appendix documents the workflow and canonical prompt used to
convert LLM chat discussions into standalone appendices in a
human-centered operators handbook. It also describes a procedure for
keeping `Index.md` in sync with the appendix files on disk. These both
exist so future chat sessions can reuse the same prompt rather than
re-deriving it, and so `Index.md` can be regenerated mechanically
instead of hand-maintained. It is human-centered for operators, hence
longer discussions of rationale and design go after initial summaries
and procedures.

#### TAGS:

* llm, prompt-engineering, rag, documentation, operator-manual,
indexing, powershell, markdown, homelab

## SCOPE AND CONSTRAINTS
   
* Applies to any appendix in this handbook that originates from an LLM
  chat discussion.
   
* Assumes appendices are named `App <number> - <Title Case Title>.md`,
  where `<number>` may be a dotted hierarchy (`2`, `2.B`, `2.B.1`)
  matching parent/child chapter relationships.
   
* Assumes each appendix contains a `## SUMMARY` section (first
  non-blank line used as the short description) and optionally
  contains a `#### TAGS: ` section (a single bullet point list containing a comma-separated line following
  the section heading of "#### TAGS: ").
   
* The generating LLM does not have a live view of the filesystem. It
  may be given either `Index.md` or a directory listing in the chat
  context to propose a placement; without that, it cannot number the
  new appendix and should say so rather than guess.

---

## PROCEDURE / USAGE

1. At the end of a homelab design discussion, paste the canonical
   prompt below into the chat, along with the current `Index.md` (or a
   directory listing) so the LLM can propose a placement.
   
2. Review the proposed appendix number and title. Confirm or adjust
   before saving.
   
3. Save the returned Markdown as `App <number> - <Title>.md` in the
   handbook directory.
   
4. Run `Create-Index` to regenerate `Index.md` from the full set of
   appendix files. Use the `-Update` parameter to seamlessly inherit
   the existing index tracking order, or specify raw files manually.

### Canonical Prompt

```text
Convert this technical discussion into a single canonical
handbook entry for an operator manual. Like a Jupyter
notebook, mix prose (rationale, constraints,
specifications) with code blocks that implement the
procedures discussed.

This document must describe the CURRENT AND CORRECT SYSTEM
STATE, not the history of how it was discovered.

Do NOT include:

* exploration history
* failed approaches, unless they directly inform a
  constraint
* conversational or iterative reasoning
* step-by-step debugging trails

Instead include ONLY:

* final architecture
* solution implemented as code in the language of the chat (powershell, bash, python, etc.)
* notes on:
  * operational guidance
  * design rationale for current choices
  * constraints that shaped the design
  * tradeoffs between relevant alternatives

If a section has nothing substantive to say, omit that
section entirely. Do not pad with filler like "not applicable" or
"no significant tradeoffs were considered."

Markdown should wrap at column 72. A single blank line should be
output between a section header and the text in the following section.

Bulleted lists should start with a "*".

Bulleted lists of longer items (one item > 50 cols) should have an empty blank line between them.

Bulleted lists should be separated by a single blank line from the preceding text.

Output Markdown in this structure:

# <TITLE>

If a chapter/appendix index or file listing is provided, use it to
place this entry in the existing hierarchy: propose an appendix number
(e.g. "App 2.G" or "App 2.D.2") that reflects where this topic fits
relative to existing chapters, and say explicitly that this is a
suggested placement for the user to confirm, not a final one. If no
index is available, state that placement couldn't be determined and
leave the number as a placeholder (e.g. "App X.Y").

Title format matches the existing corpus: "App <number> -
<Title Case Title>", e.g. "App 2.G - Local DNS
Resolution". This is also the filename as-is (spaces
included) — no separate slug needed.

#### WRITTEN: <YYYY Mon, DD HH:MM>

Date this entry was generated (YYYY Mon, DD HH:MM). If this entry
supersedes an earlier appendix, name that file here.

## SUMMARY

2-5 sentences describing the system or procedure as it
exists now.

#### TAGS:

* <comma-separated line of keywords for retrieval>

Tags is a single bullet point list containing a comma-separated list
of keywords for retrieval, wrapped at column 72.

Example:

+ systems, tools, OS, domain.

Reuse existing tags from prior appendices where the concept is the
same, rather than inventing near-duplicates (e.g. don't mix
"powershell" and "PowerShell" across documents).

## SCOPE AND CONSTRAINTS
   
What this applies to, and any important limitations or
assumptions.

## PROCEDURE / USAGE
   
The correct operational steps or configuration, if
applicable. Where a step asserts a current-state fact that
isn't self-evident, note how it was verified (command run,
date) rather than just asserting it.

## IMPLEMENTATION
   
Required whenever PROCEDURE / USAGE describes a
configuration or operational step. Complete, executable
code blocks, one per corresponding procedure step.

Rules for code blocks:
* Complete and runnable as written; no placeholders like
  "..." unless truly unavoidable
* Prefer full scripts over fragments
* Language-appropriate formatting (PowerShell, Bash, YAML,
  JSON, etc.)
* Include all required imports, parameters, and
  dependencies
* Brief explanations within code blocks
* No omitted steps required for execution
* All constants (paths, hostnames, ports, thresholds,
  file patterns, etc.) must be assigned to named variables
  at the top of the script, not embedded inline in the
  logic below. No magic strings or numbers buried in
  function bodies.

* Command line utilities (powershell, python, bash, go, etc.) should
  support typical command line discovery patterns, for example,--help,
  -h, --version, -V, --verbose, -v, exit codes and output help to
  stdout. Use common argument parsing languages when appropriate.

  Windows powershell scripts should support -Verbose, -WhatIf,
  ErrorActionPreference and a Get-Help synopsis explaining parameters
  and examples. Names should follow PowerShell verb-noun naming
  conventions.

* Follow established development standards for each language and
  platform

If multiple environments are involved, use clearly labeled
blocks:
* Windows (PowerShell)
* Linux (bash)
* Configuration files (YAML/JSON/INI)
* Infrastructure definitions (Ansible, Docker, etc.)

## DESIGN / OPERATIONAL DECISIONS
Key decisions with rationale (WHY each choice was made).

## TRADEOFFS
Only relevant alternatives considered at a design level
(not chat exploration).

## NOTES
Warnings, caveats, operational gotchas. If this topic
overlaps substantially with an existing appendix, flag
that here so it can be reconciled later.

## SEARCHABLE KEY PHRASES
5-10 phrases someone would actually type to find this
document later.

Rules:
* Be precise, technical, and stable.
* Prefer correctness over completeness of discussion
  history.
* Do not reconstruct the conversation; reconstruct the
  system.

```

---

## IMPLEMENTATION

### PowerShell — Create-Index

Accepts an ordered list of literal filenames and/or wildcard patterns
via the `$Path` array.

It can also pull file lists directly from an existing `Index.md` file
via the `-Update` switch parameter. The complete processing flow
parses the existing index first when provided, appends any manual
arguments provided via the command line, expands wildcards in place
(sorting matches dynamically by the `App N.X.Y` hierarchy), and
deduplicates the combined stream while maintaining original discovery
order. Finally, a blocklist can be specified using the `-Exclude`
parameter to strip unwanted files out of the finalized execution
chain. Each resolved file is scanned for `## SUMMARY` and `## TAGS` to
build one unified bulleted overview in the output `Index.md`.

```powershell

<#
.SYNOPSIS
    Regenerates Index.md from handbook appendix files.
 .DESCRIPTION
    Accepts an ordered list of filenames and/or wildcard patterns, 
    or parses an existing Index.md to derive baseline files.
    Processes items in original order, expands wildcards hierarchically,
    deduplicates elements, and screens out excluded sets.
 .PARAMETER Path
    Ordered filenames / wildcard patterns to combine or process.
 .PARAMETER Update
    Switch indicating that the existing index target should be read 
    to derive baseline files before combining with standard arguments.
 .PARAMETER Exclude
    An array or comma-separated set of strings specifying files to remove 
    from the final collection before parsing metadata.
 .PARAMETER Directory
    Directory to search. Defaults to current directory.
 .PARAMETER OutFile
    Output index path. Defaults to .\Index.md
#>

function Create-Index {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0,
            ValueFromRemainingArguments)]
        [string[]] $Path = @(),

        [Switch] $Update,

        [string[]] $Exclude = @(),

        [string] $Directory = (Get-Location).Path,

        [string] $OutFile = (Join-Path (Get-Location).Path 'Index.md')
    )

    # --- Constants & Patterns --------------------------
    $SummaryHeader = '## SUMMARY'
    $TagsHeader    = '## TAGS'
    $HeaderPattern = '^##\s'
    $AppNumberRx   = '^App\s+([0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)\s*-'
    $IndexLineRx   = '^\s*-\s*\*\*(.*?)\*\*'
    $MultilineOpt  = [System.Text.RegularExpressions.RegexOptions]::Multiline

    function Get-AppSortKey {
        param([string] $FileName)

        $m = [regex]::Match($FileName, $AppNumberRx)

        if (-not $m.Success) {
            # Files with no "App N - Title" pattern sort after all numbered appendices.
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
            $rest = $text.Substring($sIdx + $SummaryHeader.Length)
            $nextHeader = [regex]::Match($rest, $HeaderPattern, $MultilineOpt)
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
            $rest = $text.Substring($tIdx + $TagsHeader.Length)
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

    # --- Stage 1: Build Initial File Stream ------------
    $rawQueue = New-Object System.Collections.Generic.List[string]

    # If Update is specified, seed our queue from the target file list first
    if ($Update) {
        if (Test-Path $OutFile) {
            Write-Verbose "Reading baseline files from existing index: $OutFile"
            foreach ($line in (Get-Content $OutFile)) {
                if ($line -match $IndexLineRx) {
                    $rawQueue.Add($Matches[1])
                }
            }
        }
        else {
            Write-Warning "Update switch used, but target index file does not exist at: $OutFile"
        }
    }

    # Append explicitly passed path items
    foreach ($p in $Path) {
        $rawQueue.Add($p)
    }

    # --- Stage 2: Resolve, Expand and Sort Wildcards --
    $expandedQueue = New-Object System.Collections.Generic.List[string]

    foreach ($item in $rawQueue) {
        if ($item -match '[\*\?]') {
            $found = Get-ChildItem -Path (Join-Path $Directory $item) -File -ErrorAction SilentlyContinue
            $sorted = $found | Sort-Object { Get-AppSortKey $_.Name }
            foreach ($f in $sorted) {
                $expandedQueue.Add($f.FullName)
            }
        }
        else {
            # Could be an item found in index extraction (just filename) or full literal path
            $full = if (Split-Path $item -Parent) { $item } else { Join-Path $Directory $item }
            if (Test-Path $full) {
                $expandedQueue.Add((Resolve-Path $full).Path)
            }
            else {
                Write-Warning "File not found or unresolvable: $item"
            }
        }
    }

    # --- Stage 3: Deduplicate and Filter Exclusions ---
    $seen = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
    $finalFiles = New-Object System.Collections.Generic.List[string]

    # Normalize exclusions into a list of plain filenames for fast lookup
    $exclusionSet = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($exc in $Exclude) {
        if ($exc) {
            [void]$exclusionSet.Add((Split-Path $exc -Leaf))
        }
    }

    foreach ($pathString in $expandedQueue) {
        $leafName = Split-Path $pathString -Leaf
        
        # Check exclusion rule
        if ($exclusionSet.Contains($leafName)) {
            Write-Verbose "Excluding file matching rule: $leafName"
            continue
        }

        # Deduplicate maintaining discovery order
        if ($seen.Add($pathString)) {
            $finalFiles.Add($pathString)
        }
    }

    # --- Stage 4: Generate Output Index.md -------------
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Index')
    $lines.Add('')
    $lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd')")
    $lines.Add('')

    foreach ($file in $finalFiles) {
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
    Write-Host "Wrote $($finalFiles.Count) entries to $OutFile"
}

```

Example usage patterns matching the workflow rules:

```powershell
# Scenario A: Generate a fresh index using manual sorting configurations

Create-Index README.md, Guidelines.md, App*.md `
    -Directory 'C:\me\workspace\handbook' `
    -OutFile 'C:\me\workspace\handbook\Index.md'

# Scenario B: Read from the current Index.md, append a newly added file, and drop an old draft

Create-Index -Update -Path 'App 3.A - Draft System.md' -Exclude 'App 1.B - Old Spec.md' `
    -Directory 'C:\me\workspace\handbook' `
    -OutFile 'C:\me\workspace\handbook\Index.md'

```

---

## NOTES

* `Create-Index` uses an unapproved PowerShell verb (`Create`). This
  is intentional to match the requested name; `PSScriptAnalyzer` will
  flag it. An alias to `New-Index` can be added if that warning
  becomes annoying.

* The sort key logic assumes each numbering segment at a given depth
  is consistently either all-numeric or all-alphabetic across the
  corpus (e.g. `2`, `2.B`, `2.B.1` — number, letter, number). A
  hierarchy that mixes types at the same depth (e.g. `2.B` and `2.1`
  as siblings) would need a smarter comparer.

* The tracking engine maps files sequentially using an ordered
  execution list. Order processing priorities follow this linear
  hierarchy: `[-Update baseline inputs]` $\rightarrow$ `[Explicit
  -Path updates]` $\rightarrow$ `[Wildcard Expansions]` $\rightarrow$
  `[Deduplication]` $\rightarrow$ `[Exclusion filtering via
  -Exclude]`.

* `Handbook.md` (172 KB) is a different artifact from `Index.md` —
  this appendix concerns the index only, not a proposal to change how
  `Handbook.md` itself is assembled.

---

## DESIGN / OPERATIONAL DECISIONS

* **A single canonical prompt, reused verbatim per session.**
    Consistent structure across appendices matters more than any
    per-topic customization — it's what makes both skimming by eye and
    header-based RAG chunking reliable across the whole handbook.

* **Incremental tracking enhancements via `-Update`.** Rather than
    mandating that operators write down long file tracking arguments
    to keep historical layout arrays intact, adding an active parsing
    framework allows current files to be automatically ingested right
    out of the generated markdown document.

* **Clean output filtering via `-Exclude`.** Provides programmatic
    ability to clear decommissioned appendices or draft files from
    generating clean publication summaries without breaking filesystem
    conventions.

* **Tags as one plain line, not YAML front-matter.** These documents
    are read by a human first and a retriever second. Front-matter is
    a machine-first convention and costs readability for a personal
    corpus that doesn't need programmatic metadata queries yet.

* **A `WRITTEN` date instead of a versioning/status system.**
    Sufficient to tell, by eye, which of two appendices on the same
    subsystem is newer. If a new appendix fully replaces an old one,
    the new appendix notes the superseded filename under `WRITTEN` —
    no separate status field.

* **Hierarchical numbering mirrors the chapter structure.** The LLM
    proposes a slot (e.g. `App 2.G`) based on the visible index, but
    the placement is explicitly a suggestion for confirmation, not a
    committed decision — misfiling a chapter is more costly than a few
    seconds of confirming a number.

* **Constants declared at the top of generated scripts.** Matches the
    existing PowerShell-first, auditable style used throughout this
    handbook; no magic paths, hostnames, ports, or thresholds buried
    in logic.

* **`Index.md` is regenerated, not hand-maintained.** A script derives
    it from the appendix files themselves (via their `SUMMARY` and
    `TAGS` sections), so the index can't silently drift out of sync
    with the corpus the way a manually edited list can.

---

## TRADEOFFS

* **Automated file discovery parsing vs. pure raw directory lookups**:
    Using an incremental update flag (`-Update`) guarantees historical
    context sorting layout is maintained, but depends on regex pattern
    tracking working correctly inside `Index.md`. Standard directory
    lookups remain available as a fallback.

* **YAML front-matter vs. a plain tags line**: Front-matter rejected
    in favor of readability, since this corpus is read by a person,
    not queried by tooling.

* **Formal versioning/status fields vs. a written date**: Versioning
    rejected as unneeded ceremony for a single-author corpus; a date
    plus an optional supersedes-note carries the same information with
    far less structure.

---

## SEARCHABLE KEY PHRASES

canonical appendix prompt, LLM chat to markdown appendix, operator manual appendix generation, Create-Index PowerShell, regenerate Index.md, update existing index markdown, exclude files from index, appendix numbering sort order, App N.X.Y hierarchy, RAG-friendly handbook structure
