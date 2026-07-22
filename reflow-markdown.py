#!/usr/bin/env python3
"""Reflow Markdown prose to a target column width.

Leaves untouched:
  * fenced code blocks (``` ... ```)
  * ATX headers (#, ##, ###, ####, ...)
  * horizontal rules (---, ***, ___)
  * blank lines (paragraph separators)

Reflows:
  * plain paragraphs
  * bulleted list items (marker '*'), preserving a 2-space hanging
    indent for wrapped continuation lines, and preserving the
    existing blank-line separation between long (>50 col) bullets
"""
import re
import sys
import textwrap

WIDTH = 72
NUMBERED_RX = re.compile(r'^(\d+\.\s+)')
LIST_START_RX = re.compile(r'^(\* |\d+\.\s+)')

def is_header(line):
    return line.lstrip().startswith('#')

def is_hr(line):
    s = line.strip()
    return s in ('---', '***', '___')

def is_fence(line):
    return line.strip().startswith('```')

def flush_paragraph(buf, out):
    if not buf:
        return
    text = ' '.join(l.strip() for l in buf)

    bullet_prefix = ''
    subsequent_indent = ''
    m = NUMBERED_RX.match(text)
    if text.startswith('* '):
        bullet_prefix = '* '
        text = text[2:]
        subsequent_indent = '  '
    elif m:
        bullet_prefix = m.group(1)
        text = text[m.end():]
        subsequent_indent = ' ' * len(bullet_prefix)

    wrapped = textwrap.wrap(
        text, width=WIDTH,
        initial_indent=bullet_prefix,
        subsequent_indent=subsequent_indent,
        break_long_words=False,
        break_on_hyphens=False,
    )
    if not wrapped:
        wrapped = [bullet_prefix.rstrip()]
    out.extend(wrapped)
    buf.clear()

def reflow(text):
    lines = text.split('\n')
    out = []
    buf = []
    in_fence = False

    for line in lines:
        if is_fence(line):
            flush_paragraph(buf, out)
            in_fence = not in_fence
            out.append(line)
            continue

        if in_fence:
            out.append(line)
            continue

        if line.strip() == '':
            flush_paragraph(buf, out)
            out.append('')
            continue

        if is_header(line) or is_hr(line):
            flush_paragraph(buf, out)
            out.append(line.rstrip())
            continue

        # A line starting a new list item (at column 0) begins a new
        # paragraph even without a preceding blank line, so runs of
        # bullets that were originally one-line-per-bullet don't get
        # merged into a single paragraph.
        if LIST_START_RX.match(line) and buf:
            flush_paragraph(buf, out)

        buf.append(line)

    flush_paragraph(buf, out)
    return '\n'.join(out) + '\n'

if __name__ == '__main__':
    src = sys.stdin.read()
    sys.stdout.write(reflow(src))
