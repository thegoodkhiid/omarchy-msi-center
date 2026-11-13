# MSI Center (`tumi.msi-center`)

Omarchy shell plugin for controlling MSI laptops and desktops (Intel & AMD Ryzen, NVIDIA GeForce & AMD Radeon) directly from the status bar.

## Installation

```bash
omarchy plugin add https://github.com/thegoodkhiid/omarchy-msi-center.git --enable
```

## Features

- **Monitor Tab**:
  - Live CPU & discrete GPU telemetry (temperatures, load %, clock frequency, power draw, P-state, VRAM, DDR4/DDR5 memory temp, NVMe SSD temp).
  - Live Cooler RPM readouts (`CPU Fan 1`, `GPU Fan 2`, plus `System Fan 3/4` on desktops) via `msi_wmi_platform`, `msi-ec`, or Super I/O (`nct6775`/`nct6687`).
  - Complete **Driver & Kernel Health** verification across NVIDIA/AMD dGPU, Intel/AMD iGPU, `msi_wmi_platform`, `msi_wmi`, MSI Embedded Controller, Mystic Light USB HID, and Audio / Wi-Fi / LAN drivers.
- **Scenarios Tab**:
  - **Extreme Performance**, **Balanced**, **Silent**, and **Super Battery** scenarios synced with `powerprofilesctl` / `omarchy-powerprofiles-set` and MSI EC shift/fan modes.
  - **Cooler Boost** max-fan toggle and **Fan Mode** selector (`Auto`, `Silent`, `Cooler Boost`).
  - **CPU Turbo Boost** hardware toggle (supports both Intel `intel_pstate/no_turbo` and AMD `cpufreq/boost`).
- **Mystic Light Tab**:
  - Supports MSI MysticLight USB HID controllers (`1462:1603`, `1462:1562`, `1462:1563`, `1462:1564`), `msi-ec` keyboard backlight, and standard `/sys/class/leds/*kbd_backlight*`.
  - Effects (`Static`, `Breathing`, `Wave`, `Off`), MSI color presets (including dynamic **Omarchy Theme Accent** sync), **Backlight Intensity** (`0–100%`), and **Animation Speed** (`10–100%`).
  - Automatically restores saved RGB effect and EC permissions on login.
- **Hardware Tab**:
  - **Battery Master** charge limits (`100% · Mobility`, `80% · Balanced`, `60% · Lifespan`) with automatic Gen-1 (`0xEF`) / Gen-2 (`0xD7`) EC register detection + battery health, cycles, and power draw.
  - **General Hardware Switches**: Integrated Webcam lock, Swap `Fn` and `Super (Win)` keys, USB Power Share, and status-bar temperature readout toggle (also toggled by right-clicking the bar icon).
  - **GPU MUX & Display Outputs**: Shows Optimus/Discrete status, PCI runtime power state, and connected displays (`eDP-1`, `HDMI-A-1`, `DP-1`).
  - **Unlock Direct EC & RGB Control**: One-click Polkit setup for passwordless EC register & MysticLight HID access.

## License

MIT
