<#
.SYNOPSIS
    Consolidated Windows Baseline Sound Profile Script
.DESCRIPTION
    Configures UAC sounds, audio levels, ducking percentages, and silences aggressive system alerts.
.AUTHOR
    Jerry Asher
#>

# Ensure the core registry structures exist before writing properties
$Paths = @(
    "HKCU:\AppEvents\Schemes\Apps\.Default\WindowsUAC\.Current",
    "HKCU:\Software\Microsoft\Multimedia\Audio",
    "HKCU:\AppEvents\Schemes\Apps\.Default\SystemAsterisk\.Current",
    "HKCU:\AppEvents\Schemes\Apps\.Default\SystemNotification\.Current",
    "HKCU:\AppEvents\Schemes\Apps\.Default\SystemExclamation\.Current",
    "HKCU:\AppEvents\Schemes\Apps\.Default\.Default\.Current",
    "HKCU:\AppEvents\Schemes\Apps\.Default\SystemHand\.Current",
    "HKCU:\AppEvents\Schemes\Apps\.Default\DeviceConnect\.Current",
    "HKCU:\AppEvents\Schemes\Apps\.Default\DeviceDisconnect\.Current",
    "HKCU:\AppEvents\Schemes\Apps\.Default\MessageBeep\.Current"
)

foreach ($Path in $Paths) {
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

# --- 1. UAC Sound ---
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\WindowsUAC\.Current" -Name "(Default)" -Value "C:\Windows\Media\Windows Notify System Generic.wav"

# --- 2. Volume Slider (60%) & Ducking Value (50%) ---
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Multimedia\Audio" -Name "UserVolumeSlider" -Value 60 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Multimedia\Audio" -Name "DuckingValue" -Value 50 -Type DWord

# --- 3. Registry & System Warnings ---
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\SystemAsterisk\.Current" -Name "(Default)" -Value "C:\Windows\Media\Windows Notify.wav"
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\SystemNotification\.Current" -Name "(Default)" -Value "C:\Windows\Media\Windows Notify.wav"
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\SystemExclamation\.Current" -Name "(Default)" -Value "C:\Windows\Media\Windows Notify.wav"

# --- 4. Alert Silencing & Clean Tones ---
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\.Default\.Current" -Name "(Default)" -Value ""
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\SystemHand\.Current" -Name "(Default)" -Value "C:\Windows\Media\Windows Notify System Generic.wav"
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\DeviceConnect\.Current" -Name "(Default)" -Value "C:\Windows\Media\Windows Hardware Insert.wav"
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\DeviceDisconnect\.Current" -Name "(Default)" -Value "C:\Windows\Media\Windows Hardware Remove.wav"
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\MessageBeep\.Current" -Name "(Default)" -Value "C:\Windows\Media\Windows Notify.wav"
