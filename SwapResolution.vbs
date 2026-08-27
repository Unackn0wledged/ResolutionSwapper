' Silent launcher for SwapResolution.ps1 - runs with no console window,
' used by the desktop shortcut / hotkey created by Create-Shortcut.ps1.
Dim shell, fso, scriptDir
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & scriptDir & "\SwapResolution.ps1""", 0, False
