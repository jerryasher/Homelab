# App 10 - Recapping LLM Chats into Appendices

## WRITTEN
2026-07-03

## SUMMARY
This appendix documents the workflow and canonical prompt
used to convert LLM chat discussions about homelab design
into standalone appendices in this handbook, and the
convention for keeping an `Index.md` in sync with the
appendix files on disk. It exists so future chat sessions
(and future me) can reuse the same prompt rather than
re-deriving it, and so `Index.md` can be regenerated
mechanically instead of hand-maintained.

## TAGS
llm, prompt-engineering, rag, documentation,
operator-manual, indexing, powershell, markdown, homelab

## SCOPE AND CONSTRAINTS
- Applies to any appendix in this handbook that originates
  from an LLM chat discussion.
- Assumes appendices are named `App <number> - <Title Case
  Title>.md`, where `<number>` may be a dotted hierarchy
  (`2`, `2.B`, `2.B.1`) matching parent/child chapter
  relationships.
- Assumes each appendix contains a `## SUMMARY` section
  (first non-blank line used as the short description) and
  a `## TAGS` section (single comma-separated line).
- The generating LLM does not have a live view of the
  filesystem. It must be given either `Index.md` or a
  directory listing in the chat context to propose a
  placement; without that, it cannot number the new
  appendix and should say so rather than guess.

## DESIGN / OPERATIONAL DECISIONS
- **A single canonical prompt, reused verbatim per
  session.** Consistent structure across appendices matters
  more than any per-topic customization — it's what makes
  both skimming by eye and header-based RAG chunking
  reliable across the whole handbook.
- **Tags as one plain line, not YAML front-matter.** These
  documents are read by a human first and a retriever
  second. Front-matter is a machine-first convention and
  costs readability for a personal corpus that doesn't need
  programmatic metadata queries yet.
- **A `WRITTEN` date instead of a versioning/status
  system.** Sufficient to tell, by eye, which of two
  appendices on the same subsystem is newer. If a new
  appendix fully replaces an old one, the new appendix notes
  the superseded filename under `WRITTEN` — no separate
  status field.
- **Hierarchical numbering mirrors the chapter structure.**
  The LLM proposes a slot (e.g. `App 2.G`) based on the
  visible index, but the placement is explicitly a
  suggestion for confirmation, not a committed decision —
  misfiling a chapter is more costly than a few seconds of
  confirming a number.
- **Constants declared at the top of generated scripts.**
  Matches the existing PowerShell-first, auditable style
  used throughout this handbook; no magic paths, hostnames,
  ports, or thresholds buried in logic.
- **`Index.md` is regenerated, not hand-maintained.** A
  script derives it from the appendix files themselves
  (via their `SUMMARY` and `TAGS` sections), so the index
  can't silently drift out of sync with the corpus the way
  a manually edited list can.

## TRADEOFFS
- YAML front-matter vs. a plain tags line: front-matter
  rejected in favor of readability, since this corpus is
  read by a person, not queried by tooling.
- Formal versioning/status fields vs. a written date:
  versioning rejected as unneeded ceremony for a
  single-author corpus; a date plus an optional
  supersedes-note carries the same information with far
  less structure.

## PROCEDURE / USAGE

1. At the end of a homelab design discussion, paste the
   canonical prompt below into the chat, along with the
   current `Index.md` (or a directory listing) so the LLM
   can propose a placement.
2. Review the proposed appendix number and title. Confirm
   or adjust before saving.
3. Save the returned Markdown as `App <number> -
   <Title>.md` in the handbook directory.
4. Run `Make-Index` to regenerate `Index.md` from the full
   set of appendix files.

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
- exploration history
- failed approaches, unless they directly inform a
  constraint
- conversational or iterative reasoning
- step-by-step debugging trails

Instead include ONLY:
- final architecture or solution
- design rationale for current choices
- constraints that shaped the design
- tradeoffs between relevant alternatives
- operational guidance

If a section has nothing substantive to say, omit that
section entirely. Do not pad with filler like "no
significant tradeoffs were considered."

Output Markdown in this structure:

# TITLE
If a chapter/appendix index or file listing is available
in context, use it to place this entry in the existing
hierarchy: propose an appendix number (e.g. "App 2.G" or
"App 2.D.2") that reflects where this topic fits relative
to existing chapters, and say explicitly that this is a
suggested placement for the user to confirm, not a final
one. If no index is available, state that placement
couldn't be determined and leave the number as a
placeholder (e.g. "App X.Y").

Title format matches the existing corpus: "App <number> -
<Title Case Title>", e.g. "App 2.G - Local DNS
Resolution". This is also the filename as-is (spaces
included) — no separate slug needed.

## WRITTEN
Date this entry was generated (YYYY-MM-DD). If this entry
supersedes an earlier appendix, name that file here.

## SUMMARY
2-5 sentences describing the system or procedure as it
exists now.

## TAGS
One comma-separated line of keywords for retrieval
(systems, tools, OS, domain). Reuse existing tags from
prior appendices where the concept is the same, rather
than inventing near-duplicates (e.g. don't mix
"powershell" and "PowerShell" across documents).

## SCOPE AND CONSTRAINTS
What this applies to, and any important limitations or
assumptions.

## DESIGN / OPERATIONAL DECISIONS
Key decisions with rationale (WHY each choice was made).

## TRADEOFFS
Only relevant alternatives considered at a design level
(not chat exploration).

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
- Complete and runnable as written; no placeholders like
  "..." unless truly unavoidable
- Prefer full scripts over fragments
- Language-appropriate formatting (PowerShell, Bash, YAML,
  JSON, etc.)
- Include all required imports, parameters, and
  dependencies
- No explanation inside code blocks
- No omitted steps required for execution
- All constants (paths, hostnames, ports, thresholds,
  file patterns, etc.) must be assigned to named variables
  at the top of the script, not embedded inline in the
  logic below. No magic strings or numbers buried in
  function bodies.

If multiple environments are involved, use clearly labeled
blocks:
- Windows (PowerShell)
- Linux (bash)
- Configuration files (YAML/JSON/INI)
- Infrastructure definitions (Ansible, Docker, etc.)

## NOTES
Warnings, caveats, operational gotchas. If this topic
overlaps substantially with an existing appendix, flag
that here so it can be reconciled later.

## SEARCHABLE KEY PHRASES
5-10 phrases someone would actually type to find this
document later.

Rules:
- Be precise, technical, and stable.
- Prefer correctness over completeness of discussion
  history.
- Do not reconstruct the conversation; reconstruct the
  system.
```

## IMPLEMENTATION

### PowerShell — Make-Index

Accepts an ordered list of literal filenames and/or
wildcard patterns. Literal names are included in the exact
order given. Wildcard patterns are expanded and sorted by
the `App N.X.Y` hierarchy embedded in each filename, then
inserted at that point in the sequence. Each resolved file
is scanned for `## SUMMARY` and `## TAGS` to build one
bullet per file in the output `Index.md`.

```powershell
function Make-Index {
    <#
    .SYNOPSIS
        Regenerates Index.md from handbook appendix files.

    .DESCRIPTION
        Accepts an ordered list of filenames and/or
        wildcard patterns, e.g.:
            Make-Index README.md, Guidelines.md, App*.md
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
```

Example usage, matching the corpus in this handbook:

```powershell
Make-Index README.md, Guidelines.md, App*.md `
    -Directory 'C:\me\workspace\handbook' `
    -OutFile 'C:\me\workspace\handbook\Index.md'
```

## NOTES
- `Make-Index` uses an unapproved PowerShell verb
  (`Make`). This is intentional to match the requested
  name; `PSScriptAnalyzer` will flag it. An alias to
  `New-Index` can be added if that warning becomes
  annoying.
- The sort key logic assumes each numbering segment at a
  given depth is consistently either all-numeric or
  all-alphabetic across the corpus (e.g. `2`, `2.B`,
  `2.B.1` — number, letter, number). A hierarchy that
  mixes types at the same depth (e.g. `2.B` and `2.1` as
  siblings) would need a smarter comparer.
- `Handbook.md` (172 KB) is a different artifact from
  `Index.md` — this appendix concerns the index only, not
  a proposal to change how `Handbook.md` itself is
  assembled.

## SEARCHABLE KEY PHRASES
canonical appendix prompt, LLM chat to markdown appendix,
operator manual appendix generation, Make-Index
PowerShell, regenerate Index.md, appendix numbering
sort order, App N.X.Y hierarchy, RAG-friendly handbook
structure
