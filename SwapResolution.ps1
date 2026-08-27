#Requires -Version 5.1
<#
.SYNOPSIS
    Toggles the resolution of the primary ("main") monitor between two configured modes.

.PARAMETER To
    Force a specific target resolution instead of toggling ("3440x1440" or "2560x1440").

.PARAMETER Status
    Print the primary monitor's current resolution and exit without changing anything.

.PARAMETER Quiet
    Suppress the balloon-tip notification.

.EXAMPLE
    powershell -File SwapResolution.ps1
    Toggles between 3440x1440 and 2560x1440.

.EXAMPLE
    powershell -File SwapResolution.ps1 -To 2560x1440

.EXAMPLE
    powershell -File SwapResolution.ps1 -Status
#>
param(
    [ValidateSet('3440x1440', '2560x1440')]
    [string]$To,

    [switch]$Status,

    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'ResolutionSwapper.Core.ps1')

function Show-Notification([string]$text) {
    if ($Quiet) { return }
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $ni = New-Object System.Windows.Forms.NotifyIcon
        $ni.Icon = [System.Drawing.SystemIcons]::Information
        $ni.Visible = $true
        $ni.BalloonTipTitle = 'Resolution Swapper'
        $ni.BalloonTipText = $text
        $ni.ShowBalloonTip(3000)
        Start-Sleep -Milliseconds 3200
        $ni.Dispose()
    } catch {
        # Notification is a nice-to-have; never fail the swap because of it.
    }
}

$primaryDevice = Get-PrimaryDevice
$current = Get-CurrentMode $primaryDevice

if ($Status) {
    Write-Host "Primary monitor : $primaryDevice"
    Write-Host "Resolution      : $($current.dmPelsWidth) x $($current.dmPelsHeight) @ $($current.dmDisplayFrequency)Hz ($($current.dmBitsPerPel)-bit)"
    exit 0
}

if ($To) {
    $targetW, $targetH = $To -split 'x' | ForEach-Object { [int]$_ }
} elseif ($current.dmPelsWidth -eq 2560 -and $current.dmPelsHeight -eq 1440) {
    $targetW = 3440; $targetH = 1440
} else {
    $targetW = 2560; $targetH = 1440
}

$result = Set-MonitorResolution -Width $targetW -Height $targetH

if (-not $result.Success) {
    Write-Error $result.ErrorMessage
    exit 1
}

if ($result.AlreadySet) {
    Write-Host "Primary monitor is already $targetW x $targetH. Nothing to do."
    exit 0
}

$msg = "Main monitor switched to $targetW x $targetH @ $($result.Frequency)Hz"
Write-Host $msg
Show-Notification $msg
exit 0
