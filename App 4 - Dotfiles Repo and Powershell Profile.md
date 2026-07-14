# Dotfiles Repo Setup (Separated Git Directory)

## Overview

The dotfiles repository keeps its Git metadata separate from the tracked
files, so the work tree under `C:\me\jerry\dotfiles` has **zero `.git`
footprint** (important for OneDrive sync compatibility).

- **Git directory (repo data):** `C:\me\workspace\dotfiles\.git`
- **Work tree (tracked files):** `C:\me\jerry\dotfiles`

## Initialization

```powershell
git --git-dir="C:\me\workspace\dotfiles\.git" --work-tree="C:\me\jerry\dotfiles" init
git --git-dir="C:\me\workspace\dotfiles\.git" config core.worktree "C:\me\jerry\dotfiles"
```

No pointer file or `.git` folder is created anywhere inside
`C:\me\jerry\dotfiles`.

## Usage

Because every command needs both `--git-dir` and `--work-tree`, use a
wrapper function instead of typing them out each time.

Add to your PowerShell profile:

```powershell
function dotgit {
    git --git-dir="C:\me\workspace\dotfiles\.git" --work-tree="C:\me\jerry\dotfiles" @args
}
```

Then operate on the repo with:

```powershell
dotgit status
dotgit add .
dotgit commit -m "Update dotfiles"
dotgit push
```

## Why this approach

| Goal | Mechanism |
|---|---|
| No `.git` artifact in the synced work tree | Explicit `--git-dir` / `--work-tree`, no `init --separate-git-dir` pointer file |
| Repo data lives outside OneDrive scope | Git dir rooted at `C:\me\workspace\dotfiles\.git` |
| Day-to-day usability | `dotgit` wrapper function avoids repeating flags |

## Notes / follow-ups

- Verify `core.worktree` is set correctly with: `dotgit config --get core.worktree`
- If this gets folded into the EQR25 setup automation, the wrapper function
  and `git init` invocation should be scripted rather than run manually.
