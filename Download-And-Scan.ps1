<#
.SYNOPSIS
    Downloads a file from a URL and scans it using Microsoft Defender.
.DESCRIPTION
    This script downloads a file using Invoke-WebRequest, saves it to a specified path, 
    and automatically triggers a Microsoft Defender custom scan on the file before use.
    Supports -WhatIf and -Verbose parameters.
.PARAMETER Url
    The direct HTTP/HTTPS URL of the file to download.
.PARAMETER FilePath
    The local path (including filename) where the download should be saved.
.EXAMPLE
    Download-And-Scan.ps1 -Url "https://example.com" -FilePath "C:\Tools\script.ps1"
.EXAMPLE
    Download-And-Scan.ps1 -Url "https://example.com" -FilePath ".\installer.exe" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter the source URL to download from.")]
    [ValidateNotNullOrEmpty()]
    [string]$Url,

    [Parameter(Mandatory = $true, HelpMessage = "Enter the destination file path.")]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath
)

process {
    # Resolve the path to an absolute path so Defender can find it accurately
    $AbsoluteDocPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)

    # Wrap the action in ShouldProcess to natively support -WhatIf
    if ($PSCmdlet.ShouldProcess($AbsoluteDocPath, "Download from $Url and scan with Microsoft Defender")) {
        
        Write-Verbose "Starting download from: $Url"
        try {
            # Download the file
            Invoke-WebRequest -Uri $Url -OutFile $AbsoluteDocPath -ErrorAction Stop
            Write-Verbose "Successfully saved download to: $AbsoluteDocPath"
        }
        catch {
            Write-Error "Failed to download file. Error: $_"
            return
        }

        Write-Verbose "Initiating Microsoft Defender custom file scan..."
        try {
            # Scan the physical file
            Start-MpScan -ScanPath $AbsoluteDocPath -ScanType CustomScan -ErrorAction Stop
            Write-Verbose "Microsoft Defender scan completed successfully."
            Write-Host "Safe! File downloaded and cleared by Microsoft Defender: $AbsoluteDocPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Defender scan encountered an issue or threat detected: $_"
        }
    }
}
