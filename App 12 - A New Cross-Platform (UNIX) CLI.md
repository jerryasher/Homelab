# App 12 - A New Cross-Platform (UNIX)s CLI

#### WRITTEN: 2026 Jul, 13 17:18

## SUMMARY

The "new CLI" is a collection of modern command-line utilities that
preserve the Unix philosophy of small, composable tools while updating
their interfaces for contemporary development workflows. These tools
generally provide better defaults, improved performance, richer
output, and tighter integration with Git, source code, JSON, and YAML
than their traditional counterparts.

This document describes the core tools that are useful on Windows
under PowerShell and are available through Scoop. They complement
PowerShell rather than replacing it. PowerShell remains the preferred
tool for Windows automation and object-oriented scripting, while these
utilities excel at text processing, source code navigation, and
developer workflows.

#### TAGS

* powershell, scoop, unix, cli, developer-tools, rg, fd, jq, git

### MODERN CLI AT A GLANCE

The modern CLI does not replace the traditional Unix toolset. Rather,
it provides a collection of tools with improved defaults, better
performance, richer output, and interfaces designed around modern
developer workflows. Traditional tools remain essential for
portability and are available on virtually every Unix system, while
these newer tools are increasingly common on Linux, macOS, and
Windows.

| Traditional        | Modern      | Primary Purpose                     |
| ------------------ | ----------- | ----------------------------------- |
| `find`             | `fd`        | Find files and directories          |
| `grep`             | `rg`        | Search file contents                |
| `cat`              | `bat`       | View text and source files          |
| `ls`               | `eza`       | List directory contents             |
| `du`               | `dust`      | Visual disk usage summary           |
| `du`               | `dua`       | Interactive disk usage browser      |
| `cd`               | `zoxide`    | Jump to frequently used directories |
| `sed`              | `sd`        | Simple search and replace           |
| `time`             | `hyperfine` | Benchmark commands                  |
| *(none)*           | `fzf`       | Interactive fuzzy finder            |
| `grep`/`sed`/`awk` | `jq`        | Query and transform JSON            |
| `grep`/`sed`/`awk` | `yq`        | Query and transform YAML            |
| `git diff`         | `delta`     | Enhanced Git diff viewer            |

## SCOPE AND CONSTRAINTS

This appendix assumes:

* Windows 11

* PowerShell as the primary interactive shell

* Scoop for package management

* Git repositories are common

* WSL may be installed but is not required

These tools are intended to complement native PowerShell cmdlets.
PowerShell remains the preferred interface for Windows APIs, .NET
objects, services, scheduled tasks, the registry, and CIM/WMI.

## IMPLEMENTATION

### rg - ripgrep

`rg` is the modern replacement for recursive `grep`. It is optimized
for searching large source trees and is typically one of the fastest
ways to locate text in a project. It automatically skips binary files,
respects `.gitignore`, and uses multiple CPU cores.

For developer workflows, `rg` is generally preferable to
`Select-String` when the desired output is text rather than PowerShell
objects.

Common usage:

```text
rg PATTERN
rg PATTERN path/
rg -g '*.ps1' PATTERN
rg -i PATTERN
rg -l PATTERN
rg -n PATTERN
rg -U PATTERN
```

Examples:

```powershell
rg TODO

rg -g '*.ps1' Get-ChildItem

rg -i error logs/

rg -l 'TODO|FIXME'

rg '"version"' package.json
```

---

### fd

`fd` is a modern replacement for the common uses of `find`. It focuses
on locating files and directories with a much simpler interface,
sensible defaults, multithreaded traversal, and automatic respect for
`.gitignore`.

When complex predicates are required (ownership, timestamps,
permissions, logical expressions), traditional `find` remains the
correct tool.

Common usage:

```text
fd PATTERN
fd -e EXT
fd -t f
fd -t d
fd -H
fd -x COMMAND {}
```

Examples:

```powershell
fd '\.ps1$'

fd README

fd -e md

fd -t d node_modules

fd -x bat {}
```

---

### jq

`jq` is a structured JSON processor. Rather than treating JSON as
plain text, it understands objects, arrays, strings, numbers, and
null values, making queries both concise and reliable.

PowerShell already has excellent JSON support through
`ConvertFrom-Json`, but `jq` is often more convenient when processing
JSON produced by external programs.

Common usage:

```text
jq FILTER
jq '.field'
jq '.items[]'
jq -r FILTER
jq '. | length'
```

Examples:

```powershell
curl https://example/api | jq

jq '.users[].name' users.json

jq -r '.version' package.json

jq '.items | length'
```

---

### yq

`yq` performs the same role for YAML that `jq` performs for JSON.
Because YAML relies on indentation and nested structure, using text
tools such as `grep` or `sed` is usually fragile.

It is especially useful when working with Kubernetes, Docker Compose,
Ansible, and GitHub Actions.

Common usage:

```text
yq FILTER FILE

yq '.field'

yq '.items[]'
```

Examples:

```powershell
yq '.services' docker-compose.yml

yq '.hosts' inventory.yml

yq '.jobs.build' workflow.yml
```

---

### bat

`bat` is an enhanced file viewer intended for source code and text
files. It provides syntax highlighting, paging, Git integration, and
line numbers.

It is best thought of as a programmer's file viewer rather than a
replacement for `Get-Content`.

Common usage:

```text
bat FILE

bat -n FILE

bat --style=plain FILE
```

Examples:

```powershell
bat README.md

bat script.ps1

bat -n notes.txt
```

---

### eza

`eza` is the modern successor to `ls`. It provides improved formatting,
human-readable sizes, tree views, Git status, colors, and optional
icons.

PowerShell already produces good directory listings, so `eza` is
primarily useful when a traditional Unix-style listing is preferred.

Common usage:

```text
eza

eza -l

eza --tree

eza -la
```

Examples:

```powershell
eza

eza -l

eza --tree src

eza -la
```

---

### fzf

`fzf` is an interactive fuzzy finder. Rather than replacing an
existing utility, it provides a new style of interaction for selecting
files, commands, history entries, Git branches, or any text stream.

It becomes significantly more powerful when integrated into
PowerShell's command completion.

Common usage:

```text
COMMAND | fzf

fzf
```

Examples:

```powershell
fd | fzf

git branch | fzf

history | fzf
```

---

### delta

`delta` is a replacement pager for Git diffs. Rather than changing Git
commands, it improves their presentation through syntax highlighting,
word-level changes, side-by-side display, and improved formatting.

Once configured as Git's pager, it is largely transparent.

Common usage:

```text
git diff

git show

git log -p
```

Examples:

```powershell
git diff

git show HEAD

git log -p
```

---

### zoxide

`zoxide` is a smarter replacement for manually typing long `cd`
commands. It builds a history of frequently visited directories and
allows navigation using partial names.

It is particularly useful on systems with large source trees or many
projects.

Common usage:

```text
z NAME

zi
```

Examples:

```powershell
z ansible

z documents

z downloads
```

---

### hyperfine

`hyperfine` benchmarks command-line programs by executing them multiple
times and reporting statistically meaningful timing information. It is
far more reliable than a single invocation of the shell's `time`
command.

It is most useful when comparing competing implementations or
measuring the effect of optimizations.

Common usage:

```text
hyperfine COMMAND

hyperfine COMMAND1 COMMAND2
```

Examples:

```powershell
hyperfine "rg TODO"

hyperfine `
  "fd README" `
  "Get-ChildItem -Recurse -Filter README*"
```

---

### dust

`dust` is a visual disk usage analyzer. It provides the same basic
information as `du`, but presents it in a sorted, graphical format
that makes large directories immediately obvious.

It is intended for exploration rather than scripting.

Common usage:

```text
dust

dust DIRECTORY
```

Examples:

```powershell
dust

dust .

dust Downloads
```

---

### dua

`dua` is an interactive disk usage browser. Like `dust`, it helps
identify where storage is being consumed, but it adds navigation and
cleanup capabilities.

It is generally used only when investigating storage problems.

Common usage:

```text
dua

dua DIRECTORY
```

Examples:

```powershell
dua

dua C:\Users
```

---

### sd

`sd` is a streamlined replacement for the most common use of `sed`:
search-and-replace. It intentionally omits most of `sed`'s historical
complexity in favor of a simpler interface.

For advanced stream editing, classic `sed` remains the correct tool.

Common usage:

```text
sd SEARCH REPLACE

sd SEARCH REPLACE FILE
```

Examples:

```powershell
sd foo bar file.txt

sd '\d+' NUMBER log.txt
```

## DESIGN / OPERATIONAL DECISIONS

PowerShell and the modern CLI solve different classes of problems.

PowerShell is preferred when working with Windows infrastructure,
object pipelines, .NET types, CIM/WMI, services, scheduled tasks,
registry keys, certificates, and automation.

The modern CLI is preferred for source code, recursive text search,
structured document processing, benchmarking, fuzzy selection, and
developer workflows.

The goal is not to replace PowerShell with Unix tools, but to use each
where its design is strongest.

## TRADEOFFS

Classic Unix tools remain universally available on nearly every Unix
system and are essential for portability.

Modern replacements typically provide better defaults, improved
performance, clearer output, and simpler syntax, but may not be
installed on minimal Linux systems or embedded environments.

PowerShell cmdlets often provide richer object-oriented interfaces than
their text-oriented counterparts, but they are not always the most
ergonomic or fastest choice for interactive developer tasks.

## NOTES

All tools documented here are available through Scoop and operate
naturally from PowerShell.

These utilities are complementary rather than competitive. It is
common to combine them with PowerShell pipelines and native Windows
tools.

## SEARCHABLE KEY PHRASES

* modern command line tools

* scoop developer utilities

* ripgrep fd jq yq

* modern Unix CLI

* PowerShell developer tools

* Windows CLI utilities

* interactive terminal tools

* disk usage terminal tools

* Git command line enhancements

* modern replacements for Unix commands

## INSTALLATION

Install the complete modern CLI toolkit with Scoop:

```powershell
scoop install `
    ripgrep `
    fd `
    jq `
    yq `
    bat `
    eza `
    fzf `
    delta `
    zoxide `
    hyperfine `
    dust `
    dua `
    sd
```

Verify the installation:

```powershell
rg --version
fd --version
jq --version
yq --version
bat --version
eza --version
fzf --version
delta --version
zoxide --version
hyperfine --version
dust --version
dua --version
sd --version
```
