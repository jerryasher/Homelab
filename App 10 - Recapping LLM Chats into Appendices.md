# App 10 - Recapping LLM Chats into Appendices

#### WRITTEN: 2026 July, 06

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

#### TAGS

* llm, prompt-engineering, rag, documentation, operator-manual,
indexing, powershell, markdown, homelab

## SCOPE AND CONSTRAINTS

* Applies to any appendix in this handbook that originates from an LLM
  chat discussion.

* Assumes appendices are named `App <number> - <Title Case Title>.md`,
  where `<number>` may be a dotted hierarchy (`2`, `2.B`, `2.B.1`)
  matching parent/child chapter relationships.

* Assumes every appendix begins, in this fixed order, with: a title
  heading, a `#### WRITTEN:` line, a `## SUMMARY` section, and an
  optional `#### TAGS` section — all before any other content,
  including code blocks. This guaranteed prologue is what lets
  metadata be pulled out with a plain sequential text scan instead of
  a real Markdown parser.

* Assumes the `## SUMMARY` section's first non-blank line is the short
  description, and that `#### TAGS` (no colon), when present, is a
  single bullet containing a comma-separated list of keywords.

* A single chat discussion may cover more than one distinct subsystem
  or decision. When it does, the prompt produces one complete entry
  per topic rather than forcing a merge or silently dropping a
  thread; each such entry is independently numbered, placed, and
  saved as its own file.

* `## OPEN QUESTIONS` is included only when the discussion left
  something genuinely unresolved (a deferred decision, an unverified
  fix, a planned-but-not-done follow-up). It is omitted, like any
  other non-substantive section, when the topic reached a settled
  state.

* The generating LLM does not have a live view of the filesystem. It
  may be given either `Index.md` or a directory listing in the chat
  context to propose a placement; without that, it cannot number the
  new appendix and should say so rather than guess.

---

## PROCEDURE / USAGE

1. At the end of a homelab design discussion, paste the canonical
   prompt below into the chat, along with the current `Index.md` (or a
   directory listing) so the LLM can propose a placement.

2. Review the proposed appendix number(s) and title(s) — a single
   discussion may yield more than one entry if it covered more than
   one distinct topic. Confirm or adjust each before saving.

3. Save each returned entry as its own `App <number> - <Title>.md`
   file in the handbook directory.

4. Run `Set-Index` to regenerate `Index.md` from the full set of
   appendix files. Use the `-Update` parameter to seamlessly inherit
   the existing index tracking order, or specify raw files manually.
   Use `-WhatIf` first to preview what would be written without
   touching `Index.md`.

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

If this discussion covers more than one distinct subsystem,
procedure, or decision, do not force them into a single
entry. Produce one complete canonical entry per topic, each
following the full structure below, separated by a
horizontal rule ("---") and preceded by a one-line note
stating how many entries follow and a short reason for the
split (e.g. "2 entries: DNS resolution and the AutoHotkey
v2 migration are unrelated"). Each entry gets its own
placement suggestion and its own filename.

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

#### TAGS

* <comma-separated line of keywords for retrieval>

Tags is a single bullet point list containing a comma-separated list
of keywords for retrieval, wrapped at column 72. There is no colon
after "TAGS", and the section contains nothing besides the single
bullet.

Example:

* systems, tools, OS, domain.

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

## OPEN QUESTIONS
Include only if the discussion left something genuinely
unresolved: a decision deferred, a fix proposed but not
verified, a follow-up planned but not done. Omit entirely
if the topic reached a settled state. Do not use this
section to hedge on things that were actually resolved.

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

### PowerShell — Set-Index

Accepts an ordered list of literal filenames and/or wildcard patterns
via the `$Path` array. It can also pull a baseline file list directly
from an existing `Index.md` via the `-Update` switch. The full flow:
read the `-Update` baseline (if requested), append any manually passed
`-Path` items, expand wildcards in place (sorting each wildcard's
matches by the `App N.X.Y` hierarchy), deduplicate the combined
stream while preserving discovery order, then drop anything matching
`-Exclude`. `Set-Index` creates `OutFile` if it doesn't exist, or
overwrites it if it does; `-WhatIf` previews the write without
touching disk.

Metadata is pulled from each surviving file with a plain sequential
text scan, not a regex or Markdown parser: the scanner looks for a
line matching `## SUMMARY` or `#### TAGS` exactly, then returns the
first non-blank line after it, stopping as soon as it hits *any* line
starting with `#`. This only works because every appendix is assumed
to put its title, `WRITTEN`, `SUMMARY`, and `TAGS` sections — in that
order — before anything else, including fenced code blocks; an
appendix that puts a code sample before its own `SUMMARY` will not
scan correctly. If neither `SUMMARY` nor `TAGS` is found, `Set-Index`
writes a warning and adds the file to the index by filename only.

Output bullets always use `*`, matching the bullet convention used
inside appendices. Reading an existing `Index.md` back in via
`-Update` is more lenient: it accepts `*`, `-`, or `+` as the bullet
marker, so a hand-edited or older index still parses correctly.

```powershell

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
.EXAMPLE
    Set-Index README.md, Guidelines.md, App*.md `
        -Directory 'C:\me\workspace\handbook' `
        -OutFile 'C:\me\workspace\handbook\Index.md'

    Builds a fresh index from an explicit file list plus a
    wildcard, with the wildcard matches sorted by the
    App N.X.Y hierarchy.
.EXAMPLE
    Set-Index -Update -Path 'App 3.A - Draft System.md' `
        -Exclude 'App 1.B - Old Spec.md' `
        -Directory 'C:\me\workspace\handbook' `
        -OutFile 'C:\me\workspace\handbook\Index.md' `
        -WhatIf

    Previews reading the current Index.md, appending a new
    file, and dropping a decommissioned one, without writing
    anything.
#>

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

        [string] $OutFile = (Join-Path (Get-Location).Path 'Index.md')
    )

    # --- Constants & Patterns --------------------------
    $SummaryHeader        = '## SUMMARY'
    $TagsHeader           = '#### TAGS'
    $MarkdownHeaderMarker = '#'
    $AppNumberRx          = '^App\s+([0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)\s*-'
    $IndexLineRx          = '^\s*[\*\-\+]\s*\*\*(.*?)\*\*'
    $UnnumberedSortPrefix = 'ZZZZ'
    $OutputBulletMarker   = '*'
    $IndexDateFormat      = 'yyyy-MM-dd'
    $IndexEncoding        = 'UTF8'

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

    # Returns the first non-blank line after a header whose
    # trimmed text equals $HeaderText exactly. Stops at the
    # next line starting with "#", at any hash depth. Plain
    # text only, no regex -- this relies entirely on the
    # fixed TITLE / WRITTEN / SUMMARY / TAGS prologue that
    # every appendix is assumed to start with.
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

            if ($line.TrimStart().StartsWith($MarkdownHeaderMarker)) {
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

        $lines    = Get-Content -Path $FilePath
        $fileName = Split-Path $FilePath -Leaf

        $summary = Get-TextAfterHeader -Lines $lines -HeaderText $SummaryHeader
        $tags    = Get-TextAfterHeader -Lines $lines -HeaderText $TagsHeader

        if (-not $summary -and -not $tags) {
            Write-Warning ("No $SummaryHeader or $TagsHeader " +
                "section found in '$fileName' -- adding to " +
                "index by filename only.")
        }

        [PSCustomObject]@{
            FileName = $fileName
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

    # --- Stage 2: Resolve, Expand and Sort Wildcards ---
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

    # --- Stage 3: Deduplicate, Then Filter Exclusions --
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
        # Dedup first: a path already seen is dropped
        # regardless of whether it's also excluded.
        if (-not $seen.Add($pathString)) {
            Write-Verbose "Skipping duplicate: $pathString"
            continue
        }

        $leafName = Split-Path $pathString -Leaf
        if ($exclusionSet.Contains($leafName)) {
            Write-Verbose "Excluding file matching rule: $leafName"
            continue
        }

        $finalFiles.Add($pathString)
    }

    # --- Stage 4: Generate Output Index.md -------------
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Index')
    $lines.Add('')
    $lines.Add("Generated: $(Get-Date -Format $IndexDateFormat)")
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

    if ($PSCmdlet.ShouldProcess($OutFile, "Write $($finalFiles.Count) index entries")) {
        $lines | Set-Content -Path $OutFile -Encoding $IndexEncoding
        Write-Host "Wrote $($finalFiles.Count) entries to $OutFile"
    }
}

```

Example usage patterns matching the workflow rules:

```powershell
# Scenario A: Generate a fresh index using manual sorting configurations

Set-Index README.md, Guidelines.md, App*.md `
    -Directory 'C:\me\workspace\handbook' `
    -OutFile 'C:\me\workspace\handbook\Index.md'

# Scenario B: Preview updating the current Index.md — append a new file,
# drop an old draft — without writing anything yet

Set-Index -Update -Path 'App 3.A - Draft System.md' -Exclude 'App 1.B - Old Spec.md' `
    -Directory 'C:\me\workspace\handbook' `
    -OutFile 'C:\me\workspace\handbook\Index.md' `
    -WhatIf

```

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

* **Deduplicate before excluding.** Dropping duplicates first means a
    single `-Exclude` entry reliably removes a path no matter how many
    times it entered the queue (e.g. once from `-Update`'s baseline
    and again from an explicit `-Path` argument), instead of leaving a
    surviving duplicate behind.

* **Tags as one plain line, not YAML front-matter.** These documents
    are read by a human first and a retriever second. Front-matter is
    a machine-first convention and costs readability for a personal
    corpus that doesn't need programmatic metadata queries yet. No
    colon follows `TAGS`, matching the section's single-bullet,
    comma-separated content rather than a scalar `key: value` pair.

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
    handbook; no magic paths, hostnames, ports, thresholds, sort
    sentinels, or date formats buried in function bodies.

* **`Index.md` is regenerated, not hand-maintained.** A script derives
    it from the appendix files themselves (via their `SUMMARY` and
    `TAGS` sections), so the index can't silently drift out of sync
    with the corpus the way a manually edited list can.

* **`Set-Index`, not `New-Index` or `Update-Index`.** `Set` is the
    PowerShell verb whose approved definition already covers
    "replaces an existing value, or creates one if it doesn't exist
    yet" — exactly this function's behavior. `Update` implies
    modifying something that already exists, which doesn't cover
    Scenario A's from-scratch case.

* **Plain sequential scan instead of a Markdown parser for metadata.**
    The fixed TITLE / WRITTEN / SUMMARY / TAGS prologue every appendix
    follows removes the need for real Markdown parsing — "collect
    lines until the next `#`" is enough, at the cost of depending on
    every appendix honoring that ordering.

* **One entry per topic, not per chat session.** A session that
    meanders across unrelated subsystems shouldn't force an
    artificial merge or silently drop a thread; splitting by topic
    keeps each appendix's placement and tags coherent, at the cost of
    sometimes saving more than one file per session.

* **An explicit `OPEN QUESTIONS` section instead of forced closure.**
    Meandering chats often trail off without full resolution. Forcing
    the "current and correct state" framing onto an unresolved thread
    would manufacture false confidence; making the section optional
    (omitted when the topic is settled) keeps the existing
    "omit non-substantive sections" rule intact.

* **Asterisk bullets on output; `*`, `-`, or `+` accepted on input.**
    Output stays `*` to match the bullet convention used inside
    appendices. Input parsing is deliberately more permissive so a
    hand-edited or older `Index.md` still round-trips through
    `-Update` without needing a corrective resave first.

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

* **Sequential text scan vs. a Markdown parsing library**: A real
    parser would tolerate appendices that don't follow the fixed
    TITLE/WRITTEN/SUMMARY/TAGS prologue, but adds a dependency and
    complexity that a small, single-author, convention-following
    corpus doesn't currently need.

* **Strict output marker vs. mirroring whatever marker the input
    used**: Output always writes `*` rather than preserving whatever
    bullet character an existing `Index.md` used, trading a little
    flexibility for a visually consistent file every time `Set-Index`
    runs.

* **One appendix per chat vs. one appendix per topic**: Per-topic was
    chosen to avoid incoherent merged entries or silently dropped
    threads, at the cost of occasionally reviewing and saving more
    than one file per session.

---

## NOTES

* The sort key logic assumes each numbering segment at a given depth
  is consistently either all-numeric or all-alphabetic across the
  corpus (e.g. `2`, `2.B`, `2.B.1` — number, letter, number). A
  hierarchy that mixes types at the same depth (e.g. `2.B` and `2.1`
  as siblings) would need a smarter comparer.

* Metadata extraction depends entirely on the TITLE / WRITTEN /
  SUMMARY / TAGS prologue appearing before anything else, including
  fenced code blocks. An appendix that breaks that ordering — for
  example, one that shows an example code block before its own
  `SUMMARY` — will not scan correctly, silently or with a warning
  depending on what it does find.

* `Set-Index` processes candidates in this order: `-Update` baseline
  → explicit `-Path` items → wildcard expansion (sorted per item) →
  deduplication → exclusion filtering. Deduplication running before
  exclusion means a single `-Exclude` entry removes a path no matter
  how many times it entered the queue.

* `Handbook.md` (172 KB) is a different artifact from `Index.md` —
  this appendix concerns the index only, not a proposal to change how
  `Handbook.md` itself is assembled.

---

## SEARCHABLE KEY PHRASES

canonical appendix prompt, LLM chat to markdown appendix, operator manual appendix generation, Set-Index PowerShell, regenerate Index.md, update existing index markdown, exclude files from index, appendix numbering sort order, App N.X.Y hierarchy, RAG-friendly handbook structure, PowerShell WhatIf index generation, multi-topic appendix split, open questions section, one appendix per topic
