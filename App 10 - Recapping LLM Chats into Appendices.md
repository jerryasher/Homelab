# App 10 - Recapping LLM Chats into Appendices

#### WRITTEN: 2026 July, 06

## SUMMARY

This appendix documents the workflow and canonical prompt used to
convert LLM chat discussions into standalone appendices in a
human-centered operators handbook. It also describes a procedure for
keeping `Index.md` in sync with the appendix files on disk, and a
procedure for pulling each embedded script back out of its appendix
and onto disk as a standalone file. These exist so future chat
sessions can reuse the same prompt rather than re-deriving it, so
`Index.md` can be regenerated mechanically instead of hand-maintained,
and so embedded scripts can be restored to disk mechanically instead
of hand-copied out of a code block. It is human-centered for
operators, hence longer discussions of rationale and design go after
initial summaries and procedures.

#### TAGS

* llm, prompt-engineering, rag, documentation, operator-manual,
indexing, powershell, markdown, homelab, script-extraction

## SCOPE AND CONSTRAINTS

* Applies to any appendix in this handbook that originates from an LLM
  chat discussion.

* Assumes appendices are named `App <number> - <Title Case Title>.md`,
  where `<number>` may be a dotted hierarchy (`2`, `2.B`, `2.B.1`)
  matching parent/child chapter relationships.

* Assumes every appendix begins, in this fixed order, with: a title
  heading, a `#### WRITTEN:` line, a `## SUMMARY` section, and an
  optional `#### TAGS` section - all before any other content,
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

* Every embedded script (any fenced code block meant to be saved and
  run, as opposed to an inline example or fragment) is immediately
  preceded by a single line of the form `#### FILE: <filename>`,
  separated from the code fence by nothing but the standard single
  blank line. This is what lets a script be pulled back out of its
  appendix mechanically: the same plain sequential text scan already
  used for `SUMMARY` and `TAGS` extraction can also recognize this
  marker and hand the following fenced block to a file of that name.

* All generated Markdown and source files are UTF-8 encoded.

* Prefer printable ASCII characters throughout prose, Markdown, and
  code.

* Emit non-ASCII Unicode characters only when they are semantically
  required (for example, when discussing Unicode itself, reproducing
  externally-defined text, or when correctness depends on the specific
  character).

---

## PROCEDURE / USAGE

1. At the end of a homelab design discussion, paste the canonical
   prompt below into the chat, along with the current `Index.md` (or a
   directory listing) so the LLM can propose a placement.

2. Review the proposed appendix number(s) and title(s) - a single
   discussion may yield more than one entry if it covered more than
   one distinct topic. Confirm or adjust each before saving.

3. Save each returned entry as its own `App <number> - <Title>.md`
   file in the handbook directory.

4. Run `Set-Index` to regenerate `Index.md` from the full set of
   appendix files. Use the `-Update` parameter to seamlessly inherit
   the existing index tracking order, or specify raw files manually.
   Use `-WhatIf` first to preview what would be written without
   touching `Index.md`.

5. If a script embedded in an appendix needs to live on disk as its
   own file (to run it, diff it, or check it into source control),
   run `Export-AppendixScript` against that appendix - or against
   `Index.md` via `-IndexFile` to sweep every appendix at once -
   rather than hand-copying the code block out.

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

Output UTF-8 encoded Markdown. Prefer printable ASCII characters
throughout. Avoid typographic punctuation and invisible Unicode
characters unless they are semantically required

Use -- instead of an em dash.
Use - instead of an en dash.
Use -> instead of any unicode arrow.
Use straight quotes (" and '), never smart quotes.
Use ... instead of the ellipsis character.
Use ordinary ASCII spaces, never non-breaking or zero-width spaces.

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
included) - no separate slug needed.

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
* Complete and runnable as written. Saving the code block to the
  specified filename and executing it directly must perform the
  documented behavior without requiring additional wrapper code,
  manual edits, or calls from another script.

* Unless explicitly requested otherwise, every generated source file
  is a standalone command-line program, not a reusable library or
  module.

* Do not generate a file consisting solely of function, class, or
  method definitions. The file itself must execute the documented
  behavior when run directly.

* Prefer full scripts over fragments

* Generated source code should consist entirely of printable ASCII
  unless the program being implemented explicitly requires Unicode
  data or characters.

* Comments, help text, and usage messages should also follow the
  printable ASCII preference unless a Unicode character is required
  for correctness.

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

* Every embedded script gets a clearly delineated filename
  immediately above its code fence, on its own line, in the
  form `#### FILE: <filename>`, separated from the fence by
  nothing but a single blank line. This lets the script be
  mechanically extracted back to disk later. Inline
  examples or fragments not meant to be saved as their own
  file omit this marker.

* Filenames, identifiers, variable names, function names, and
  command-line options should use printable ASCII only.

* Command line utilities (powershell, python, bash, go, etc.) should
  support typical command line discovery patterns, for example,--help,
  -h, --version, -V, --verbose, -v, exit codes and output help to
  stdout. Use common argument parsing languages when appropriate.

* Windows PowerShell command-line scripts should behave like native
  PowerShell tools. They should support -Verbose, -WhatIf (when
  appropriate), $ErrorActionPreference, and Get-Help
  documentation. They may organize their implementation using advanced
  functions, but executing the .ps1 file must immediately perform the
  documented operation.

* For every language, follow that ecosystem's normal executable
  program conventions. Include the language's customary top-level
  execution mechanism (for example, a script body, main(), or
  equivalent) so the generated file behaves as a complete command-line
  program.

* Follow established development standards for each language and
  platform

* Whenever quoting existing text, filenames, command output,
  specifications, or protocols that legitimately contain Unicode,
  preserve those characters exactly rather than transliterating them.

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

Unless a Unicode character is required for technical correctness,
generated output should be visually and byte-for-byte reproducible
using printable ASCII characters encoded as UTF-8.

```

---

## IMPLEMENTATION

### PowerShell - Set-Index

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
to put its title, `WRITTEN`, `SUMMARY`, and `TAGS` sections - in that
order - before anything else, including fenced code blocks; an
appendix that puts a code sample before its own `SUMMARY` will not
scan correctly. If neither `SUMMARY` nor `TAGS` is found, `Set-Index`
writes a warning and adds the file to the index by filename only.

Output bullets always use `*`, matching the bullet convention used
inside appendices. Reading an existing `Index.md` back in via
`-Update` is more lenient: it accepts `*`, `-`, or `+` as the bullet
marker, so a hand-edited or older index still parses correctly.

The file is a standalone command-line program: it carries its own
top-level `param()` block (giving it native `-WhatIf`, `-Verbose`,
and `Get-Help` support without any extra wiring), plus `-Version` and
`-Help` switches, and its last line invokes the `Set-Index` function
with whatever was bound at the command line. Running
`.\Set-Index.ps1 ...` performs the operation immediately; dot-sourcing
the file first (`. .\Set-Index.ps1`) also loads `Set-Index` as a
reusable function for the rest of the session, for composing into
other scripts.

#### FILE: Set-Index.ps1

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
            $line += " - $($meta.Summary)"
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
```

Example usage patterns matching the workflow rules (run directly; the
same calls work identically if you dot-source the file first and
call the `Set-Index` function on its own):

```powershell
# Scenario A: Generate a fresh index using manual sorting configurations

.\Set-Index.ps1 README.md, Guidelines.md, App*.md `
    -Directory 'C:\me\workspace\handbook' `
    -OutFile 'C:\me\workspace\handbook\Index.md'

# Scenario B: Preview updating the current Index.md - append a new file,
# drop an old draft - without writing anything yet

.\Set-Index.ps1 -Update -Path 'App 3.A - Draft System.md' -Exclude 'App 1.B - Old Spec.md' `
    -Directory 'C:\me\workspace\handbook' `
    -OutFile 'C:\me\workspace\handbook\Index.md' `
    -WhatIf

```

### PowerShell - Export-AppendixScript

Reverses the embedding direction: instead of writing a script into an
appendix, it pulls a script back out. It accepts an ordered list of
literal filenames and/or wildcard patterns via `$Path`, an optional
`-IndexFile` pointing at an `Index.md` (or any file using the same
bulleted-entry format) to derive the appendix list instead of naming
each one by hand, or both combined. The two sources are merged in
order (`-IndexFile` entries first, then `-Path`), deduplicated, and
resolved to full paths, reusing the same wildcard-expansion approach
as `Set-Index`.

Each resolved appendix file is scanned with the same plain sequential
text-scan philosophy as `Get-AppendixMetadata`: walk the lines looking
for `#### FILE: <filename>`, skip any blank lines immediately after
it, then require the very next non-blank line to open a fenced code
block. Everything up to the matching closing fence is written to
`<filename>` under `-OutputDirectory`. A marker not immediately
followed by a fence - for example, one separated from its code block
by unexpected prose - is skipped with a warning rather than guessed
at. A single appendix may contain more than one `FILE` marker; all are
extracted in one pass.

An existing destination file is left untouched and a warning is
issued unless `-Force` is supplied, and `-WhatIf` previews every write
(including creation of `-OutputDirectory` itself) without touching
disk.

Extracted files are written directly via
`[System.IO.File]::WriteAllText` rather than `Set-Content`, joined
with a literal `` `n `` and encoded UTF-8 without a byte order mark.
This guarantees LF line endings on every platform regardless of
`Set-Content`'s host-dependent default (CRLF on Windows), so a script
pulled out of an appendix on a Windows workstation is byte-for-byte
comparable to one pulled out on Linux - important for diffing
extracted scripts against what's checked into source control. The
destination path is resolved to a full, absolute path before any of
this happens (via `[System.IO.Path]::GetFullPath`, which works
whether or not the file yet exists), and that same full path - not
just the bare filename - is what gets echoed to output once a file
is written, so the confirmation message is unambiguous about where
the file landed regardless of what `-OutputDirectory` or the current
working directory happened to be.

Like `Set-Index.ps1`, the file is a standalone command-line program:
a top-level `param()` block gives it native `-WhatIf`, `-Verbose`,
and `Get-Help` support, `-Version` and `-Help` switches are handled
before anything else runs, and the file's last line invokes the
`Export-AppendixScript` function with whatever was bound at the
command line. Running `.\Export-AppendixScript.ps1 ...` performs the
extraction immediately; dot-sourcing it first also loads
`Export-AppendixScript` as a reusable function for the session.

#### FILE: Export-AppendixScript.ps1

```powershell

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
```

Example usage patterns (run directly; the same calls work identically
if you dot-source the file first and call the `Export-AppendixScript`
function on its own):

```powershell
# Scenario A: Extract every embedded script from one appendix

.\Export-AppendixScript.ps1 'App 10 - Recapping LLM Chats into Appendices.md' `
    -Directory 'C:\me\workspace\handbook' `
    -OutputDirectory 'C:\me\workspace\handbook\scripts'

# Scenario B: Preview a full sweep of every appendix in Index.md,
# overwriting anything already extracted

.\Export-AppendixScript.ps1 -IndexFile 'C:\me\workspace\handbook\Index.md' `
    -Directory 'C:\me\workspace\handbook' `
    -OutputDirectory 'C:\me\workspace\handbook\scripts' `
    -Force -WhatIf

```

---

## DESIGN / OPERATIONAL DECISIONS

* **A single canonical prompt, reused verbatim per session.**
    Consistent structure across appendices matters more than any
    per-topic customization - it's what makes both skimming by eye and
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
    the new appendix notes the superseded filename under `WRITTEN` -
    no separate status field.

* **Hierarchical numbering mirrors the chapter structure.** The LLM
    proposes a slot (e.g. `App 2.G`) based on the visible index, but
    the placement is explicitly a suggestion for confirmation, not a
    committed decision - misfiling a chapter is more costly than a few
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
    yet" - exactly this function's behavior. `Update` implies
    modifying something that already exists, which doesn't cover
    Scenario A's from-scratch case.

* **Plain sequential scan instead of a Markdown parser for metadata.**
    The fixed TITLE / WRITTEN / SUMMARY / TAGS prologue every appendix
    follows removes the need for real Markdown parsing - "collect
    lines until the next `#`" is enough, at the cost of depending on
    every appendix honoring that ordering.

* **A `#### FILE:` marker line instead of a comment inside the code
    fence.** Reuses the same heading-marker, sequential-scan
    convention already established by `WRITTEN` and `TAGS`, so one
    scanning technique covers both metadata and script extraction.
    A marker inside the fence (e.g. a leading `# FILE:` comment)
    would need per-language comment-syntax handling (`#`, `//`,
    `--`, etc.); a Markdown-level marker is language-agnostic and
    works identically for PowerShell, Bash, Python, or anything
    else.

* **`Export-AppendixScript`, not `Get-` or `Extract-`.** `Export` is
    an approved PowerShell verb whose definition already covers
    "store data in an external representation" - exactly this
    function's behavior of turning an in-Markdown code block back
    into a standalone file on disk. `Extract` isn't an approved
    verb; `Get` implies retrieval without necessarily writing
    anything to disk.

* **A top-level `param()` block that forwards into an inner function
    of the same name, via `@PSBoundParameters`, rather than either a
    bare script or a function-only file.** A function-only file (the
    earlier shape of both scripts) can be dot-sourced but does
    nothing when run directly, which fails the requirement that
    executing the `.ps1` immediately perform the operation. A bare
    script with no inner function would satisfy that but couldn't be
    dot-sourced and reused as a named command within a longer-running
    session or another script. Duplicating the parameter list once
    at the script scope and once on the function costs a little
    repetition, but keeps both entry points fully native - CLI
    invocation gets real parameter binding, `-WhatIf`/`-Verbose`, and
    `Get-Help` for free, and dot-sourcing gets a normal reusable
    function back.

* **Explicit `-Version` and `-Help` switches in addition to
    PowerShell's built-in `-?` and `Get-Help`.** Costs two extra
    parameters and a few lines per script, but matches the
    command-line discovery conventions (`--help`/`-h`,
    `--version`/`-V`) this handbook expects from every language,
    rather than assuming an operator already knows PowerShell's own
    discovery mechanisms.

* **Forced LF, no-BOM output via `WriteAllText` instead of
    `Set-Content`.** `Set-Content` writes line endings matching the
    host platform's default (CRLF on Windows), which is fine for
    Windows-only artifacts but wrong for a script that might be
    extracted on Windows and then diffed or committed alongside
    copies extracted on Linux. Bypassing `Set-Content` for a direct
    `[System.IO.File]::WriteAllText` call with an explicit `` `n ``
    join costs a little directness, but makes extraction output
    reproducible byte-for-byte regardless of platform.

* **Echoing the full resolved destination path, not the bare
    filename, on success.** A bare filename reads fine when
    `-OutputDirectory` is the current directory, but is ambiguous or
    misleading otherwise (e.g. sweeping many appendices into a
    dedicated `scripts` folder from a different working directory).
    Resolving via `[System.IO.Path]::GetFullPath` before the write
    also means the same resolved path is used for both the
    existing-file check and the confirmation message, so there's no
    chance the two disagree.

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

* **A required `FILE` marker vs. inferring a filename from context**:
    An earlier option considered was inferring a script's filename
    from its section heading (e.g. "PowerShell - Set-Index" implying
    `Set-Index.ps1`). Requiring an explicit marker instead costs one
    extra line per script, but removes any ambiguity when a heading
    doesn't map cleanly to a filename (multiple scripts under one
    heading, or a config file with no natural verb-noun name), and
    keeps extraction independent of heading wording ever changing.

---

## NOTES

* The sort key logic assumes each numbering segment at a given depth
  is consistently either all-numeric or all-alphabetic across the
  corpus (e.g. `2`, `2.B`, `2.B.1` - number, letter, number). A
  hierarchy that mixes types at the same depth (e.g. `2.B` and `2.1`
  as siblings) would need a smarter comparer.

* Metadata extraction depends entirely on the TITLE / WRITTEN /
  SUMMARY / TAGS prologue appearing before anything else, including
  fenced code blocks. An appendix that breaks that ordering - for
  example, one that shows an example code block before its own
  `SUMMARY` - will not scan correctly, silently or with a warning
  depending on what it does find.

* `Set-Index` processes candidates in this order: `-Update` baseline
  -> explicit `-Path` items -> wildcard expansion (sorted per item) ->
  deduplication -> exclusion filtering. Deduplication running before
  exclusion means a single `-Exclude` entry removes a path no matter
  how many times it entered the queue.

* `Handbook.md` (172 KB) is a different artifact from `Index.md` -
  this appendix concerns the index only, not a proposal to change how
  `Handbook.md` itself is assembled.

* `Export-AppendixScript` depends on the same ordering fragility as
  `Get-AppendixMetadata`: a `#### FILE:` marker not immediately
  followed (after only blank lines) by an opening code fence is
  skipped with a warning rather than guessed at. An appendix written
  before this convention existed will have no markers at all and
  simply yields nothing extractable until it is updated.

* Appendices predating this convention (including earlier revisions
  of this one) will not have `#### FILE:` markers on their embedded
  scripts. There is no bulk-retrofit tool; markers are added the next
  time an appendix is touched.

* Review generated output for accidental typographic Unicode
  characters (smart quotes, em/en dashes, ellipses, non-breaking
  spaces, zero-width characters). These are considered formatting
  artifacts rather than intentional content and should normally be
  replaced with their ASCII equivalents.

---

## SEARCHABLE KEY PHRASES

canonical appendix prompt, LLM chat to markdown appendix, operator manual appendix generation, Set-Index PowerShell, regenerate Index.md, update existing index markdown, exclude files from index, appendix numbering sort order, App N.X.Y hierarchy, RAG-friendly handbook structure, PowerShell WhatIf index generation, multi-topic appendix split, open questions section, one appendix per topic, Export-AppendixScript PowerShell, extract embedded script from markdown, FILE marker convention, restore script from appendix, script filename in code block
