<#
.SYNOPSIS
    Creates a Desktop shortcut for SwapResolution that also carries a global
    keyboard shortcut (Windows .lnk files support this natively - no extra
    hotkey software needed).

.PARAMETER HotkeyModifier
    Modifier combo for the hotkey, e.g. "Ctrl+Alt" or "Ctrl+Shift+Alt".

.PARAMETER HotkeyKey
    The key to combine with the modifier, e.g. "R".

.PARAMETER ShortcutName
    File name (without extension) for the shortcut on the Desktop.

.EXAMPLE
    powershell -File Create-Shortcut.ps1
    Creates "Swap Resolution.lnk" on the Desktop bound to Ctrl+Alt+R.

.EXAMPLE
    powershell -File Create-Shortcut.ps1 -HotkeyModifier "Ctrl+Shift+Alt" -HotkeyKey "P"
#>
param(
    [string]$HotkeyModifier = 'Ctrl+Alt',
    [string]$HotkeyKey = 'R',
    [string]$ShortcutName = 'Swap Resolution'
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbsPath = Join-Path $scriptDir 'SwapResolution.vbs'

if (-not (Test-Path $vbsPath)) {
    Write-Error "Could not find SwapResolution.vbs next to this script."
    exit 1
}

$desktop = [Environment]::GetFolderPath('Desktop')
$lnkPath = Join-Path $desktop "$ShortcutName.lnk"

$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($lnkPath)
$shortcut.TargetPath = 'wscript.exe'
$shortcut.Arguments = "`"$vbsPath`""
$shortcut.WorkingDirectory = $scriptDir
$shortcut.WindowStyle = 7
$shortcut.Description = 'Toggle main monitor between 3440x1440 and 2560x1440'
$shortcut.IconLocation = 'shell32.dll,137'
$shortcut.HotKey = "$HotkeyModifier+$HotkeyKey"
$shortcut.Save()

Write-Host "Shortcut created: $lnkPath"
Write-Host "Hotkey bound    : $HotkeyModifier+$HotkeyKey (works while the shortcut exists on disk)"
