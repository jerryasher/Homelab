Get-ChildItem -Path *.md,*.txt -File |
ForEach-Object {
    if (dos2unix -ic -- $_.FullName) {
        Write-Host "Converting $($_.Name)"
        dos2unix -- $_.FullName
    }
}
