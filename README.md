# MSI Center (`oma.msi-center`)

**MSI Center** is a native [Omarchy](https://omarchy.org/) status-bar plugin that brings complete hardware control, thermal telemetry, **User Scenarios**, **Cooler Boost**, **Mystic Light RGB**, and **Battery Master** charge limits to MSI laptops and desktops on Arch Linux.

---

## Quick Install, Update & Removal

### Install

```bash
omarchy plugin add https://github.com/thegoodkhiid/omarchy-msi-center.git --enable
```

### Update

```bash
omarchy plugin update oma.msi-center
```

### Disable or Uninstall

Temporarily hide it from the status bar without uninstalling:

```bash
omarchy plugin disable oma.msi-center
```

Completely remove the plugin:

```bash
omarchy plugin remove oma.msi-center
```

*(Optional)* If you used the **Unlock Direct EC & RGB Control** button and want to remove the system udev/module/sudoers rules as well:

```bash
sudo rm -f /etc/sudoers.d/omarchy-msi-center \
           /etc/udev/rules.d/60-msi-mysticlight.rules \
           /etc/modules-load.d/msi-center.conf \
           /etc/modprobe.d/msi-center.conf
```

---

## Features

### 1. Monitor Tab — Live Telemetry & Driver Diagnostics
- **CPU & Discrete GPU Cards**:
  - Live CPU temperature (`°C`), load (`%`), average clock speed (`GHz`), and core count (`coretemp`, `k10temp`, `zenpower`).
  - Live NVIDIA GeForce (`nvidia-smi`) or AMD Radeon (`amdgpu` sysfs) temperature, utilization (`%`), power draw (`W`), P-state, and VRAM usage (`MiB`).
- **System Memory & Storage**:
  - System RAM usage (`GiB`), DDR4/DDR5 SPD temperature (`spd5118` / `jc42`), and NVMe SSD temperature (`nvme`).
- **Cooler RPM Readouts**:
  - Real-time `CPU Fan 1` and `GPU Fan 2` RPMs (plus `System Fan 3` & `System Fan 4` on MSI desktops) via `msi_wmi_platform`, `msi-ec`, or Super I/O (`nct6775` / `nct6687`).
- **6-Point Driver & Kernel Health Check**:
  - Automatically verifies discrete GPU drivers (`nvidia` / `amdgpu`), integrated GPU (`i915` / `xe` / `amdgpu`), `msi_wmi_platform` + `msi_wmi`, MSI Embedded Controller (`msi-ec` / `ec_sys`), Mystic Light USB HID (`1462:*`), and Audio / Wi-Fi / LAN kernel modules.

### 2. Scenarios Tab — Performance Profiles & Cooling
- **MSI User Scenarios**:
  - **Extreme Performance**: Switches `powerprofilesctl` to `performance`, enables CPU Turbo Boost, and sets the MSI EC shift register to `Turbo` (`0xC4`).
  - **Balanced**: Adaptive performance and acoustics (`comfort` / `0xC1`).
  - **Silent**: Quiet fan curve and low noise (`silent` / `0x1D`).
  - **Super Battery**: Power-saver profile, Eco EC shift (`0xC2`), Super Battery mode, and reduced boost.
- **Cooler Boost & Fan Mode**:
  - Instant **Cooler Boost** max-fan toggle (`100%` CPU & GPU fan speed) — also accessible from the top-right action button in the panel hero header.
  - **Fan Mode** selector: `Auto`, `Silent`, and `Cooler Boost`.
- **CPU Turbo Boost Toggle**:
  - Hardware toggle for Intel Turbo Boost (`intel_pstate/no_turbo`) and AMD Core Performance Boost (`cpufreq/boost`).

### 3. Mystic Light Tab — RGB Effects, Intensity & Speed
- **Hardware Support**:
  - Native 64-byte HID feature-report driver for MSI MysticLight controllers (`1462:1603`, `1462:1562`, `1462:1563`, `1462:1564`), plus `msi-ec` keyboard backlight and standard `/sys/class/leds/*kbd_backlight*`.
- **Effects**:
  - `Static`, `Breathing` (smooth cosine pulse), `Wave` (24-zone scrolling rainbow spectrum), and `Off`.
- **Color Presets & Omarchy Theme Sync**:
  - `MSI Red`, `Cyber Cyan`, `Venom Green`, `Neon Purple`, `Amber Gold`, `Pure White`, and **Theme Accent** (automatically matches your active Omarchy theme accent color).
- **Sliders**:
  - **Backlight Intensity** (`0–100%`, 5% steps) — smoothly scales per-channel RGB output and EC hardware backlight levels (`0xD3`).
  - **Animation Speed** (`10–100%`, 5% steps) — controls both the hardware transition speed and dynamic **Breathing** / **Wave** animation cadence.
- **Automatic Login Restore**:
  - Automatically restores your saved RGB mode, color, brightness, and animation speed on login.

### 4. Hardware Tab — Battery Master & Hardware Switches
- **Battery Master (Charge Limit)**:
  - **100% · Mobility**, **80% · Balanced**, and **60% · Lifespan** charge thresholds (supports standard `charge_control_end_threshold` as well as automatic Gen-2 `0xD7` and Gen-1 `0xEF` MSI EC register detection).
  - Displays battery health (`%`), cycle count, charge status, and real-time power draw (`W`).
- **General Hardware Switches**:
  - **Integrated Webcam** hardware lock (`msi-ec` / EC `0x2E` & `0x2F` + `uvcvideo`).
  - **Swap `Fn` and `Super (Win)` Keys** (`msi-ec` / EC `0xE8`).
  - **USB Power Share** sleep charging (`msi-ec` / EC `0xBF`).
  - **Show CPU/GPU Temp in Status Bar** — also toggled by **right-clicking** the MSI Center bar icon.
- **GPU MUX & Display Outputs**:
  - Shows graphics routing mode (`Hybrid / Optimus` or `Discrete PCIe`), dGPU PCI runtime status, and connected display outputs (`eDP-1`, `HDMI-A-1`, `DP-1`, etc.).
- **One-Click Polkit Setup**:
  - Clicking **Unlock Direct EC & RGB Control** uses a one-time Polkit prompt to configure `ec_sys write_support=1` and `1462:*` `hidraw` udev rules so all future toggles are instant and passwordless.

---

## Bar Interaction & Keyboard Shortcuts / IPC

- **Left-click** the bar icon: Open / close MSI Center.
- **Right-click** the bar icon: Toggle live CPU temperature readout next to the icon.
- **Left / Right arrow keys** while open: Switch between the **Monitor**, **Scenarios**, **Mystic Light**, and **Hardware** tabs.

You can also bind Hyprland shortcuts or trigger actions from the terminal via `omarchy-shell`:

```bash
# Toggle the MSI Center popup panel
omarchy-shell oma.msi-center toggle

# Toggle Cooler Boost max-fan mode directly
omarchy-shell oma.msi-center coolerBoost

# Toggle the status-bar temperature readout
omarchy-shell oma.msi-center toggleBarTemp
```

Or use the bundled `msi-center-ctl` CLI directly:

```bash
~/.config/omarchy/plugins/oma.msi-center/bin/msi-center-ctl status
~/.config/omarchy/plugins/oma.msi-center/bin/msi-center-ctl scenario extreme
~/.config/omarchy/plugins/oma.msi-center/bin/msi-center-ctl cooler-boost toggle
~/.config/omarchy/plugins/oma.msi-center/bin/msi-center-ctl mystic wave "#00E5FF" 100 65
~/.config/omarchy/plugins/oma.msi-center/bin/msi-center-ctl battery-limit 80
```

---

## Hardware Compatibility & Safety

- **Supported Systems**:
  - MSI Gaming & Creator Laptops (Katana, Sword, Pulse, Crosshair, Vector, Raider, Stealth, Titan, Cyborg, Prestige, Modern — Intel & AMD Ryzen).
  - MSI Desktops (telemetry, fan monitoring, power scenarios, and Mystic Light USB HID).
- **Safe EC Register Validation**:
  - Uses `/sys/devices/platform/msi-ec` whenever supported by the running kernel.
  - On newer 13th/14th-gen MSI laptops (such as `MS-17T2` / `17T2EMS1`) where `msi_wmi_platform` handles WMI and `ec_sys` handles EC registers, direct EC writes are strictly gated on verifying both a laptop chassis and a valid MSI `*EMS*` firmware signature at `0xA0..0xAB`.

---

## Validation & Tests

```bash
# Validate Omarchy plugin manifest & structure
omarchy plugin validate ~/.config/omarchy/plugins/oma.msi-center

# Run state sanitization & markup-neutralization regression tests
node ~/.config/omarchy/plugins/oma.msi-center/tests/model-test.js
```

---

## License

[MIT](LICENSE)
