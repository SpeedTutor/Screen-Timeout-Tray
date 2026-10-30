# Screen Timeout Tray

A lightweight, open-source **Windows 11 system tray utility** for quickly changing when your laptop screen turns off. No installation, Python, or .NET SDK required: it uses Windows PowerShell 5.1 and Windows Forms already included with Windows.

## Features

- Tray icon near the clock; right-click for instant timeout choices.
- Independent **On battery** and **Plugged in** display timeouts.
- Windows-style presets: 1, 2, 3, 5, 10, 15, 20, 25, 30, 45 minutes; 1, 2, 3, 4, 5 hours; or Never.
- Small settings window, with Apply and Refresh buttons.
- Reads your current active power plan settings; shows checked options.
- Nothing runs in the background after Exit.
- Doesn't change sleep, hibernation, or screen lock settings.

## Run

1. Download and extract the project folder.
2. Double-click **`Launch.vbs`**.
3. Right-click the blue monitor icon in the system tray (the `^` overflow menu may contain it), or use the opened window.
4. Choose separate battery and plugged-in timeouts. Settings take effect immediately.
5. Closing the window leaves the tray icon running; right-click and choose **Exit** to quit.

**Optional startup:** Press `Win + R`, type `shell:startup`, press Enter, and place a **shortcut to `Launch.vbs`** in that folder. Keep the app files in a permanent location if you do this.

## How it works

Uses the Microsoft-supported commands:

```powershell
powercfg.exe /change monitor-timeout-ac 30
powercfg.exe /change monitor-timeout-dc 10
```

Reads the active power plan with:

```powershell
powercfg.exe /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE
```

Changes affect only the **currently active** power plan. The app does not need to remain open for the timeout changes to persist. On managed company laptops, organization policy may override changes. Some Windows laptops also have presence sensing or a separate lock-screen timeout that works independently.

## Security and requirements

- Windows 11 (also expected to run on Windows 10), built-in Windows PowerShell 5.1.
- `Launch.vbs` starts PowerShell invisibly with `-ExecutionPolicy Bypass` **for this process only**. It does not change the machine's configured PowerShell execution policy. Review the script before running it.
- No internet access, analytics, installers, registry edits, or administrator prompt requested.
- Some enterprise security software may restrict `.vbs` or PowerShell scripts. If blocked, follow your IT policy rather than bypassing organizational controls.

## GitHub

Create a new public GitHub repository named `screen-timeout-tray` and upload these files (including `LICENSE`). Include a screenshot if you wish.

## License

MIT — see [LICENSE](LICENSE).
