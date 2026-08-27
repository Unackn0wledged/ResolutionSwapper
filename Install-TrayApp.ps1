<#
.SYNOPSIS
    Sets up the Resolution Swapper tray icon: starts it now, and (by
    default) makes it launch automatically at login by placing a shortcut
    in your Startup folder.

.PARAMETER NoAutostart
    Only start the tray icon for this session; don't add it to Startup.

.PARAMETER NoLaunch
    Only set up autostart; don't start the tray icon now.

.EXAMPLE
    powershell -File Install-TrayApp.ps1

.EXAMPLE
    powershell -File Install-TrayApp.ps1 -NoAutostart
    Starts the tray icon for this session only.
#>
param(
    [switch]$NoAutostart,
    [switch]$NoLaunch
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbsPath = Join-Path $scriptDir 'TrayApp.vbs'

if (-not (Test-Path $vbsPath)) {
    Write-Error "Could not find TrayApp.vbs next to this script."
    exit 1
}

if (-not $NoAutostart) {
    $startupDir = [Environment]::GetFolderPath('Startup')
    $lnkPath = Join-Path $startupDir 'Resolution Swapper Tray.lnk'

    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($lnkPath)
    $shortcut.TargetPath = 'wscript.exe'
    $shortcut.Arguments = "`"$vbsPath`""
    $shortcut.WorkingDirectory = $scriptDir
    $shortcut.WindowStyle = 7
    $shortcut.Description = 'Resolution Swapper tray icon (auto-starts at login)'
    $shortcut.IconLocation = 'shell32.dll,137'
    $shortcut.Save()

    Write-Host "Autostart shortcut created: $lnkPath"
}

if (-not $NoLaunch) {
    Start-Process -FilePath 'wscript.exe' -ArgumentList "`"$vbsPath`""
    Write-Host "Tray icon started."
    Write-Host "Windows 11 hides new tray icons by default - click the ^ arrow"
    Write-Host "near the clock and drag the icon out to keep it always visible."
}
