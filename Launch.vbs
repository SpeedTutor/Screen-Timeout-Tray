' Starts the tray app without a PowerShell console window.
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
folder = fso.GetParentFolderName(WScript.ScriptFullName)
command = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File " & Chr(34) & folder & "\ScreenTimeoutTray.ps1" & Chr(34)
shell.Run command, 0, False
