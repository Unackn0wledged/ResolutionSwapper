#Requires -Version 5.1
<#
.SYNOPSIS
    Persistent system tray icon for Resolution Swapper. Right-click it to
    pick a resolution for the main monitor, or double-click to toggle.

    Must run in a Single-Threaded Apartment (Windows Forms requirement) -
    launch via TrayApp.vbs, or manually with:
        powershell -sta -NoProfile -File TrayApp.ps1
#>

$ErrorActionPreference = 'Stop'

if ($Host.Runspace.ApartmentState -ne 'STA') {
    Write-Error "TrayApp.ps1 must run in STA mode. Launch it via TrayApp.vbs, or 'powershell -sta -File TrayApp.ps1'."
    exit 1
}

. (Join-Path $PSScriptRoot 'ResolutionSwapper.Core.ps1')

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ('ResSwap.IconExtractor' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace ResSwap {
    public static class IconExtractor {
        [DllImport("shell32.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr ExtractIcon(IntPtr hInst, string lpszExeFileName, int nIconIndex);
    }
}
"@
}

$trayIcon = $null
try {
    $hIcon = [ResSwap.IconExtractor]::ExtractIcon([IntPtr]::Zero, 'shell32.dll', 137)
    if ($hIcon -ne [IntPtr]::Zero) {
        $trayIcon = [System.Drawing.Icon]::FromHandle($hIcon)
    }
} catch { }
if (-not $trayIcon) { $trayIcon = [System.Drawing.SystemIcons]::Application }

$RES_ULTRAWIDE = @{ W = 3440; H = 1440; Label = 'Ultrawide  (3440 x 1440)' }
$RES_STANDARD  = @{ W = 2560; H = 1440; Label = 'Standard   (2560 x 1440)' }

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = $trayIcon
$notifyIcon.Text = 'Resolution Swapper'
$notifyIcon.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip

$headerItem = New-Object System.Windows.Forms.ToolStripMenuItem('Current: ...')
$headerItem.Enabled = $false
[void]$menu.Items.Add($headerItem)
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$itemUltrawide = New-Object System.Windows.Forms.ToolStripMenuItem($RES_ULTRAWIDE.Label)
$itemStandard  = New-Object System.Windows.Forms.ToolStripMenuItem($RES_STANDARD.Label)
[void]$menu.Items.Add($itemUltrawide)
[void]$menu.Items.Add($itemStandard)
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$itemExit = New-Object System.Windows.Forms.ToolStripMenuItem('Exit')
[void]$menu.Items.Add($itemExit)

$notifyIcon.ContextMenuStrip = $menu

function Update-MenuState {
    try {
        $primary = Get-PrimaryDevice
        $current = Get-CurrentMode $primary
        $headerItem.Text = "Current: $($current.dmPelsWidth) x $($current.dmPelsHeight) @ $($current.dmDisplayFrequency)Hz"
        $itemUltrawide.Checked = ($current.dmPelsWidth -eq $RES_ULTRAWIDE.W -and $current.dmPelsHeight -eq $RES_ULTRAWIDE.H)
        $itemStandard.Checked  = ($current.dmPelsWidth -eq $RES_STANDARD.W  -and $current.dmPelsHeight -eq $RES_STANDARD.H)
    } catch {
        $headerItem.Text = 'Current: unknown'
    }
}

function Invoke-Switch([int]$w, [int]$h) {
    $r = Set-MonitorResolution -Width $w -Height $h
    if ($r.Success) {
        if (-not $r.AlreadySet) {
            $notifyIcon.BalloonTipTitle = 'Resolution Swapper'
            $notifyIcon.BalloonTipText = "Main monitor switched to $w x $h"
            $notifyIcon.ShowBalloonTip(2500)
        }
    } else {
        $notifyIcon.BalloonTipTitle = 'Resolution Swapper - Error'
        $notifyIcon.BalloonTipText = $r.ErrorMessage
        $notifyIcon.ShowBalloonTip(4000)
    }
    Update-MenuState
}

$menu.add_Opening({ Update-MenuState })
$itemUltrawide.add_Click({ Invoke-Switch $RES_ULTRAWIDE.W $RES_ULTRAWIDE.H })
$itemStandard.add_Click({ Invoke-Switch $RES_STANDARD.W $RES_STANDARD.H })
$itemExit.add_Click({
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$notifyIcon.add_MouseDoubleClick({
    param($eventSender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        if ($itemUltrawide.Checked) {
            Invoke-Switch $RES_STANDARD.W $RES_STANDARD.H
        } else {
            Invoke-Switch $RES_ULTRAWIDE.W $RES_ULTRAWIDE.H
        }
    }
})

Update-MenuState
[System.Windows.Forms.Application]::Run()
