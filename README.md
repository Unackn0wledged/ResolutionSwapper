# ResolutionSwapper

A small, dependency-free Windows utility that switches your **primary
monitor's** resolution between two preset modes — via a double-click, a
keyboard shortcut, or a tray icon menu — without opening Display Settings.

Example setup this was built for:

| Monitor | Native resolution | Notes |
|---|---|---|
| Main (ultrawide) | `3440x1440` | everyday use |
| Side | `1440x2560` (portrait) | secondary display |

Some applications don't support the main monitor's native 21:9 ultrawide
aspect ratio and look better (or only work correctly) at the standard 16:9
`2560x1440`. This tool switches the **main monitor only** back and forth
between `3440x1440` and `2560x1440`, in about a second. The side monitor
is untouched.

## Features

- **Three ways to trigger it**: double-click, a global keyboard hotkey, or
  a tray icon with a right-click menu — pick whichever fits your workflow.
- Tray icon shows the **current resolution** and puts a checkmark next to
  the active mode, so you always know what you're on before you switch.
- Always targets whichever display Windows currently considers **primary**
  — no config file to edit if you change your setup.
- Preserves color depth and picks the highest available refresh rate for
  the target resolution.
- `-Status` flag to check the current resolution without changing anything.
- `-To <resolution>` flag to force a specific resolution instead of
  toggling.
- Small Windows balloon notification confirming the switch (optional).
- Optional Desktop shortcut with a **built-in Windows keyboard shortcut**
  (e.g. `Ctrl+Alt+R`) — no third-party hotkey software required.
- Optional tray icon can auto-start at login.
- Pure PowerShell + Win32 API calls — nothing to install, no compiled
  executables.

## Requirements

- Windows 10/11
- PowerShell 5.1+ (included with Windows)
- The target resolution must already be available on your main monitor.
  `2560x1440` is a standard resolution that most ultrawide monitors
  (including 3440x1440 panels) list natively, so this typically works with
  no extra setup. If your monitor doesn't offer a resolution you want to
  toggle to, add it once as a custom resolution via your GPU's control
  panel (NVIDIA Control Panel → *Display > Change Resolution > Customize*,
  AMD Software → *Custom Resolutions*) or a tool like
  [Custom Resolution Utility (CRU)](https://www.monitortests.com/forum/Thread-Custom-Resolution-Utility-CRU).
  Once Windows reports the mode as available, this tool can switch to it.

## Installation

1. Download or clone this repository anywhere on your machine.
2. That's it — no build step, no installer.

```bash
git clone https://github.com/<your-username>/ResolutionSwapper.git
```

## Usage

### Quick toggle

Double-click **`SwapResolution.bat`**. It switches the main monitor to the
other configured resolution and shows a brief confirmation notification.
If something goes wrong, the console window stays open so you can read the
error.

### Silent toggle (for shortcuts/hotkeys)

**`SwapResolution.vbs`** runs the same swap with no console window at all.
This is what the hotkey shortcut (below) uses.

### Set up a global hotkey (recommended)

Run once:

```powershell
powershell -File Create-Shortcut.ps1
```

This creates a **"Swap Resolution"** shortcut on your Desktop bound to
`Ctrl+Alt+R` by default. Windows shortcut hotkeys work system-wide as long
as the shortcut file exists (on the Desktop or in the Start Menu) — no
background process needed. Press the hotkey any time; alt-tab out first
if the foreground application is running exclusive fullscreen.

To use a different key combination:

```powershell
powershell -File Create-Shortcut.ps1 -HotkeyModifier "Ctrl+Shift+Alt" -HotkeyKey "P"
```

### Tray icon with a right-click menu

Run once:

```powershell
powershell -File Install-TrayApp.ps1
```

This starts a tray icon immediately and adds it to your Startup folder so
it comes back automatically every time you log in. Right-click it for:

- **Current: 2560 x 1440 @ 144Hz** — a disabled header showing what the
  main monitor is running right now.
- **Ultrawide (3440 x 1440)** / **Standard (2560 x 1440)** — click either
  to switch straight to it; a checkmark shows which one is active.
- **Exit** — closes the tray icon (it won't relaunch until next login,
  or until you run it again).

Double-clicking the icon toggles between the two, same as `SwapResolution.bat`.

Windows 11 hides newly-installed tray icons under the **^** overflow arrow
next to the clock by default — click it once and drag the Resolution
Swapper icon out onto the taskbar if you want it always visible.

Useful variations:

```powershell
# Start the tray icon for this session only, don't add it to Startup
powershell -File Install-TrayApp.ps1 -NoAutostart

# Only set up Startup autostart, don't launch it right now
powershell -File Install-TrayApp.ps1 -NoLaunch
```

To remove autostart later, delete `Resolution Swapper Tray.lnk` from your
Startup folder (`Win+R` → `shell:startup`).

### Command line

```powershell
# Toggle between the two configured resolutions
powershell -File SwapResolution.ps1

# Force a specific resolution
powershell -File SwapResolution.ps1 -To 2560x1440
powershell -File SwapResolution.ps1 -To 3440x1440

# Just check what the main monitor is currently running, no changes made
powershell -File SwapResolution.ps1 -Status

# Toggle without the balloon notification
powershell -File SwapResolution.ps1 -Quiet
```

## How it works

[`ResolutionSwapper.Core.ps1`](ResolutionSwapper.Core.ps1) holds the shared
logic, used by both `SwapResolution.ps1` (CLI) and `TrayApp.ps1` (tray
icon). It uses the Win32 `EnumDisplaySettings` / `ChangeDisplaySettingsEx`
APIs (via P/Invoke) to:

1. Find the current primary display (`System.Windows.Forms.Screen`).
2. Read its current resolution.
3. Look up a supported mode matching the requested width/height,
   preferring the same color depth and the highest refresh rate available.
4. Apply it and persist the change to the registry, so it survives a
   reboot like a normal resolution change would.

`SwapResolution.ps1` decides the target (toggle, or whatever you passed to
`-To`) and prints/notifies the result. `TrayApp.ps1` hosts a
`NotifyIcon` + `ContextMenuStrip` and calls the same core function per menu
click. No window flicker, no Display Settings UI, no external executables.

## Customizing the two resolutions

The target resolutions appear in three places — update all three to
whatever pair you want to toggle between:

- [`SwapResolution.ps1`](SwapResolution.ps1): the
  `ValidateSet('3440x1440', '2560x1440')` on the `$To` parameter, and the
  `2560`/`1440` check a few lines below it.
- [`TrayApp.ps1`](TrayApp.ps1): the `$RES_ULTRAWIDE` / `$RES_STANDARD`
  hashtables near the top (width, height, and menu label).

## Troubleshooting

**"does not report a WxH mode"** — Windows doesn't know that resolution
exists for this monitor yet. Add it as a custom resolution via your GPU
control panel or CRU (see [Requirements](#requirements)), then try again.

**Windows rearranges my icons/taskbar after switching** — this is normal
Windows behavior when resolution changes, not specific to this tool.

**The hotkey doesn't fire** — Windows `.lnk` hotkeys don't work while
another application holds exclusive-fullscreen focus; switch it to
borderless/windowed, or alt-tab out first. Also make sure the shortcut
created by `Create-Shortcut.ps1` hasn't been moved or deleted from the
Desktop.

**I don't see the tray icon** — Windows 11 hides new tray icons under the
`^` overflow arrow next to the clock; click it and drag the icon out. If
it's not there at all, check it's actually running:
`Get-Process powershell | Where-Object CommandLine -match TrayApp` (in a
PowerShell 7+ session) — or just run `Install-TrayApp.ps1` again.

**`TrayApp.ps1 must run in STA mode`** — you launched it directly with
plain `powershell -File TrayApp.ps1`. Use `TrayApp.vbs` (or
`Install-TrayApp.ps1`, which uses it) — Windows Forms requires an STA
runspace, which needs the `-Sta` flag.

## Ideas for further features

- Auto-detect and remember a preferred resolution per application,
  switching automatically when that process starts/exits.
- Multi-monitor profiles (swap main *and* reposition/rescale the side
  monitor together) using `SetDisplayConfig` for atomic multi-display
  changes.
- A toast notification (Windows 10/11 native toast) instead of the classic
  tray balloon.
- A custom `.ico` for the tray/shortcut instead of the borrowed
  `shell32.dll` monitor icon.

## License

No license file is included yet — add one (e.g. MIT) if you plan to share
or accept contributions on GitHub.
