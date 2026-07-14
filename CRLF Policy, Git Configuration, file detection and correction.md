# Git Line Ending Policy (LF Everywhere)

## Goal

Use LF (`\n`) line endings everywhere:

- Repository: LF
- Working tree: LF
- No automatic CRLF translation by Git

This makes behavior consistent across Windows, Linux, WSL, and macOS.

## Git Configuration

Check the current configuration:

```powershell
git config --show-origin --get-regexp 'core\.(autocrlf|eol)|safecrlf'
```

Recommended global configuration:

```powershell
git config --global core.autocrlf false
git config --global --unset core.eol
git config --global safecrlf true
```

A repository `.gitattributes` should contain:

```text
# Auto detect text files and store them with LF
* text=auto eol=lf
```

With this configuration, Git stores LF in the repository and does not automatically check out CRLF files.

## Detecting CRLF Files

### Inside a Git repository

Show Git's view of line endings:

```powershell
git ls-files --eol
```

Look for:

- `i/lf w/lf` – ideal
- `i/lf w/crlf` – working tree contains CRLF
- `w/mixed` – mixed line endings

### Outside (or inside) a repository

Using ripgrep:

```powershell
rg -U -l '\r'
```

Using the `file` utility (Git Bash or another POSIX shell):

```bash
file *
```

Using `dos2unix` to list files with DOS line endings:

```powershell
Get-ChildItem -Path *.md,*.txt -File |
ForEach-Object {
    if (dos2unix -ic -- $_.FullName) {
        $_.Name
    }
}
```

## Converting CRLF to LF

Convert a single file:

```powershell
dos2unix filename.txt
```

Convert selected Markdown and text files in the current directory:

```powershell
Get-ChildItem -Path *.md,*.txt -File |
ForEach-Object {
    if (dos2unix -ic -- $_.FullName) {
        Write-Host "Converting $($_.Name)"
        dos2unix -- $_.FullName
    }
}
```

After conversion, verify with:

```powershell
git ls-files --eol
```

or

```powershell
rg -U -l '\r'
```
