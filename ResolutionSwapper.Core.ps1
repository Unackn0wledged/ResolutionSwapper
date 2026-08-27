# Shared Win32 display-mode logic used by SwapResolution.ps1 and TrayApp.ps1.
# Dot-source this file; it defines types/functions only, no top-level output.

if (-not ('ResSwap.Native' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace ResSwap
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    public static class Native
    {
        public const int ENUM_CURRENT_SETTINGS = -1;
        public const int CDS_UPDATEREGISTRY = 0x1;
        public const int DISP_CHANGE_SUCCESSFUL = 0;

        [DllImport("user32.dll", CharSet = CharSet.Ansi)]
        public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

        [DllImport("user32.dll", CharSet = CharSet.Ansi)]
        public static extern int ChangeDisplaySettingsEx(string deviceName, ref DEVMODE devMode, IntPtr hwnd, int dwflags, IntPtr lParam);
    }
}
"@
}

function Get-PrimaryDevice {
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [System.Windows.Forms.Screen]::AllScreens | Where-Object { $_.Primary } | Select-Object -First 1
    if (-not $screen) { throw "Could not find a primary display device." }
    return $screen.DeviceName
}

function Get-CurrentMode([string]$deviceName) {
    $dm = New-Object ResSwap.DEVMODE
    $dm.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($dm)
    $ok = [ResSwap.Native]::EnumDisplaySettings($deviceName, [ResSwap.Native]::ENUM_CURRENT_SETTINGS, [ref]$dm)
    if (-not $ok) { throw "Could not read current display settings for $deviceName." }
    return $dm
}

function Get-AllModes([string]$deviceName) {
    $modes = @()
    $i = 0
    while ($true) {
        $dm = New-Object ResSwap.DEVMODE
        $dm.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($dm)
        $ok = [ResSwap.Native]::EnumDisplaySettings($deviceName, $i, [ref]$dm)
        if (-not $ok) { break }
        $modes += $dm
        $i++
    }
    return $modes
}

# Switches the primary monitor to Width x Height. Returns a result object;
# never throws for an expected/handleable failure (unsupported mode, API
# failure) so callers (CLI or tray) can report it without a try/catch.
function Set-MonitorResolution {
    param(
        [Parameter(Mandatory)] [int]$Width,
        [Parameter(Mandatory)] [int]$Height
    )

    $primary = Get-PrimaryDevice
    $current = Get-CurrentMode $primary

    if ($current.dmPelsWidth -eq $Width -and $current.dmPelsHeight -eq $Height) {
        return [PSCustomObject]@{
            Success      = $true
            AlreadySet   = $true
            Width        = $Width
            Height       = $Height
            Frequency    = $current.dmDisplayFrequency
            Device       = $primary
            ErrorMessage = $null
        }
    }

    $allModes = Get-AllModes $primary
    $candidates = $allModes | Where-Object { $_.dmPelsWidth -eq $Width -and $_.dmPelsHeight -eq $Height }

    if (-not $candidates -or $candidates.Count -eq 0) {
        return [PSCustomObject]@{
            Success      = $false
            AlreadySet   = $false
            Width        = $Width
            Height       = $Height
            Frequency    = $null
            Device       = $primary
            ErrorMessage = "The primary monitor ($primary) does not report a $Width x $Height mode. Add it as a custom resolution via your GPU control panel or CRU first."
        }
    }

    $sameDepth = $candidates | Where-Object { $_.dmBitsPerPel -eq $current.dmBitsPerPel }
    $pool = if ($sameDepth) { $sameDepth } else { $candidates }
    $chosen = $pool | Sort-Object dmDisplayFrequency -Descending | Select-Object -First 1

    $result = [ResSwap.Native]::ChangeDisplaySettingsEx($primary, [ref]$chosen, [IntPtr]::Zero, [ResSwap.Native]::CDS_UPDATEREGISTRY, [IntPtr]::Zero)

    if ($result -eq [ResSwap.Native]::DISP_CHANGE_SUCCESSFUL) {
        return [PSCustomObject]@{
            Success      = $true
            AlreadySet   = $false
            Width        = $Width
            Height       = $Height
            Frequency    = $chosen.dmDisplayFrequency
            Device       = $primary
            ErrorMessage = $null
        }
    } else {
        return [PSCustomObject]@{
            Success      = $false
            AlreadySet   = $false
            Width        = $Width
            Height       = $Height
            Frequency    = $null
            Device       = $primary
            ErrorMessage = "ChangeDisplaySettingsEx failed with code $result."
        }
    }
}
