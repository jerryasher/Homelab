# App 10.1 - Revise and Retrofit of Older Documents

#### WRITTEN: 2026 Jul, 08 12:00

## SUMMARY

This appendix documents a companion prompt to App 10's canonical
conversion prompt, used to bring an existing appendix that predates
or drifted from the App 10 standard back into conformance. Unlike
the canonical prompt, which synthesizes a new appendix from a chat
discussion, this prompt takes an already-written appendix and the
App 10 spec as its two inputs and produces the minimal set of edits
needed to satisfy that spec, plus a changelog mapping each edit to
the rule it satisfies. It exists so bringing the appendix corpus's
backlog into compliance is a repeatable, reviewable operation rather
than an ad hoc rewrite each time.

#### TAGS

* llm, prompt-engineering, documentation, operator-manual, markdown,
homelab, conformance, legacy-appendix, diff-review

## SCOPE AND CONSTRAINTS

* Applies to any appendix already saved to disk that needs to be
  brought into conformance with the standard defined in App 10,
  whether because it predates that standard or has drifted from it.

* Not a substitute for App 10's canonical prompt. App 10 converts a
  raw chat discussion into a new appendix; this appendix converts an
  existing, already-structured appendix into a conformant one. The
  two prompts are used at different points in the workflow and are
  not interchangeable.

* The generating LLM is given both the App 10 spec and the target
  appendix as input. It does not have independent knowledge of
  either; both must be pasted or attached in full.

* Preserve existing prose, examples, and voice wherever the
  structure already conforms. This is an edit-in-place operation,
  not a regeneration - the smaller the diff against the original,
  the better the result.

* Do not invent content (rationale, tradeoffs, constraints) that
  isn't already present or directly implied by the document as
  written. Where the spec requires something the document does not
  support (for example, a TRADEOFFS section with no discernible
  rejected alternative), flag it explicitly rather than guessing at
  plausible-sounding content.

* All generated Markdown is UTF-8 encoded and prefers printable
  ASCII, consistent with App 10's own constraints.

---

## PROCEDURE / USAGE

1. Paste or attach the full text of App 10 (this handbook's
   standard) alongside the appendix to be brought into conformance.

2. Run the canonical retrofit prompt below against both.

3. Review the returned changelog against the diff of the returned
   document versus the original. Each listed change should trace to
   a specific App 10 rule; if it doesn't, treat that change as
   unjustified and revert it.

4. Save the corrected appendix over the original file (or as a new
   revision, per the handbook's normal git workflow).

5. If the appendix's placement or filename changes as part of the
   correction, run `Set-Index` to regenerate `Index.md` afterward.

### Canonical Retrofit Prompt

```text

This document is an existing appendix in a homelab operator's
handbook. Bring it up to the standard defined in "App 10 -
Recapping LLM Chats into Appendices" (attached/pasted below),
making the MINIMAL set of changes needed to comply.

Do NOT rewrite prose that already complies. Do NOT re-derive or
restate content that is already correct. Preserve the author's
existing wording, examples, and voice wherever the structure
already matches the spec.

Check specifically for:

* Correct prologue order: title heading, `#### WRITTEN:` line,
  `## SUMMARY`, optional `#### TAGS` - in that order, before any
  other content including code blocks.
* Presence and placement of required sections (SUMMARY, SCOPE
  AND CONSTRAINTS, PROCEDURE / USAGE, IMPLEMENTATION, DESIGN /
  OPERATIONAL DECISIONS, TRADEOFFS, NOTES, SEARCHABLE KEY
  PHRASES) and correct omission of sections with nothing
  substantive to say (do not pad).
* `## OPEN QUESTIONS` present only if something is genuinely
  unresolved; add it if the doc reveals an unresolved item, omit
  otherwise.
* Every complete executable artifact (not inline
  fragments/snippets) has a `#### FILE: <filename>` marker
  immediately before its code fence, separated only by a single
  blank line. Add missing markers; do not add markers to
  fragments that were never meant to be standalone files.
* Executable artifacts otherwise meet the rules in App 10
  (complete/runnable as-is, no bare function-only files, named
  constants instead of magic strings/numbers, printable ASCII,
  standard CLI discovery flags, PowerShell -WhatIf/-Verbose/
  Get-Help where appropriate).
* Markdown wraps at column 72; single blank line between a
  section header and its text; bulleted lists use `*`; long
  bullets (>50 cols) are blank-line separated.
* ASCII punctuation throughout (-- not em dash, - not en dash,
  -> not arrow glyphs, straight quotes, ... not ellipsis
  character, no non-breaking/zero-width spaces) except where
  Unicode is semantically required.
* `#### TAGS` is a single bullet, comma-separated, reusing
  existing corpus tags where the concept already has one rather
  than inventing near-duplicates.

If bringing the doc into compliance requires inventing new
content (e.g. a TRADEOFFS section didn't exist but the doc
clearly implies a rejected alternative), only add it if it can
be derived from what's already stated in the document - do not
speculate or add content that isn't supported by the existing
text. If something required by the spec cannot be determined
from the document as written, flag it explicitly rather than
guessing.

Output the full corrected document. At the end, separately list
every change made and the specific App 10 rule each change
satisfies, so the diff can be reviewed quickly.

--- App 10 spec follows ---
[paste or attach App 10 in full]

--- Document to bring into compliance follows ---
[paste or attach the target appendix]

```

---

## DESIGN / OPERATIONAL DECISIONS

* **A separate prompt rather than reusing App 10's canonical
  prompt.** The canonical prompt is optimized for synthesis from an
  unstructured chat discussion, where regenerating the whole
  document in a consistent voice is the point. Retrofitting an
  already-structured appendix has the opposite goal: the smallest
  possible diff. Sharing one prompt for both tasks would mean
  constantly overriding its default synthesis behavior with ad hoc
  instructions each time, which is exactly the kind of re-deriving
  App 10 itself was written to avoid.

* **A required changelog mapping each change to a specific App 10
  rule.** Without it, reviewing a retrofit means re-reading the
  whole document against the spec by hand, which is the manual
  effort this prompt exists to remove. Requiring a rule citation per
  change also discourages the model from making unjustified
  stylistic edits, since every change has to be defensible against a
  named constraint.

* **Explicit instruction to flag rather than guess when the spec
  demands something the document doesn't support.** Older
  appendices sometimes predate sections like TRADEOFFS or OPEN
  QUESTIONS entirely. Fabricating plausible-sounding rationale to
  fill such a section would misrepresent the document's actual
  history; flagging the gap keeps the corrected appendix honest
  about what it does and doesn't know.

---

## TRADEOFFS

* **Minimal-diff correction vs. full regeneration**: A full
    regeneration through App 10's canonical prompt would guarantee
    consistent voice and structure across the whole corpus, but
    would also discard original phrasing, examples, and any
    context an LLM re-deriving the document from scratch might
    silently lose. Minimal-diff correction preserves the original
    author's intent at the cost of occasionally leaving stylistic
    inconsistencies between older and newer appendices.

* **Changelog requirement vs. plain corrected output**: Requiring a
    per-change rule citation costs extra output length and a second
    pass of self-checking by the model, but turns review from a
    full re-read into a spot check against a short list.

---

## NOTES

* This prompt assumes the appendix being corrected is otherwise
  legitimate content worth preserving - it is a compliance pass, not
  a content review. Judging whether the appendix's substance is
  still accurate or worth keeping remains a separate, human step.

* There is no bulk-retrofit tool for running this prompt across the
  whole backlog automatically; each appendix is still reviewed and
  saved individually, consistent with App 10's own note that markers
  and conventions are adopted incrementally as appendices are
  touched.

---

## SEARCHABLE KEY PHRASES

appendix conformance pass, retrofit older appendix, bring appendix
up to standard, App 10 companion prompt, minimal diff document
correction, legacy appendix conversion, appendix changelog review,
FILE marker retrofit, handbook backlog compliance
