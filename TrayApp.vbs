' Silent launcher for TrayApp.ps1 - runs with no console window.
' TrayApp.ps1 needs an STA runspace (Windows Forms requirement).
Dim shell, fso, scriptDir
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File """ & scriptDir & "\TrayApp.ps1""", 0, False
