---
name: matepad-pro
description: >-
  Operations, diagnostics, and app lifecycle management for the Huawei MatePad Pro (MRX-W09)
  fleet tablet. Covers headless APK installation, GBox sandboxing, Shizuku privilege escalation,
  ADB reverse tunnels (Weylus, RDP, DroidCam), battery preservation, and diagnostic telemetry.
---
# Huawei MatePad Pro (MRX-W09) Fleet Guide

## 1. Device Profile & Hardware

- **Device Model**: Huawei MatePad Pro (`MRX-W09`, codename `HWMRX`)
- **ADB Serial**: `QBK6R20825000010` (USB connected, fast charging / AC powered)
- **SoC**: HiSilicon Kirin 990 4G (7nm, 8-core: 2x Cortex-A76 @ 2.86GHz, 2x A76 @ 2.09GHz, 4x A55 @ 1.86GHz)
- **GPU**: Mali-G76 MP16 | **NPU**: DaVinci dual-core NPU
- **Memory & Storage**: 6GB LPDDR4X RAM, 128GB UFS 3.0 storage
- **Display**: 10.8" IPS LCD, 2560x1600 (16:10, 280 ppi, DCI-P3)
- **OS**: EMUI 10.1 (Android 10 base, non-GMS / no native Google Play Services)
- **Launcher**: Lawnchair 14 (`app.lawnchair`)
- **Declarative Host Config**: `nix-config/hosts/tablet/default.nix` & `nix-config/modules/nixos/android.nix`

---

## 2. Fleet Roles & Declarative Conductor Recipes

The tablet serves four primary roles in the `kleinbem` workstation setup:

1. **Secondary Display & Stylus Digitizer (Weylus)**:
   - Connects to host Weylus server via ADB reverse tunnel on port `1701`.
   - Launch declaratively via `just android::tablet-screen` in `nix-config`.
2. **Remote Desktop / RDP Extended Display**:
   - Reverse tunnel on port `3389` via GNOME Remote Desktop.
   - Launch declaratively via `just android::tablet-rdp` in `nix-config`.
3. **Webcam & Microphone (DroidCam)**:
   - Reverse tunnel on port `4747` feeding `/dev/video10` (v4l2loopback).
   - Launch declaratively via `just android::tablet-cam` in `nix-config`.
4. **All-in-One Desk Companion Mode**:
   - `just android::tablet-desk` (establishes all tunnels, caps battery charge at 80% to protect Li-poly cell, disables idle sleep, and starts Shizuku).

---

## 3. Headless App Installation (No Screen Scraping)

> [!IMPORTANT]
> **NEVER use pixel hunting, screen coordinate guessing, or screenshot OCR to install apps.**
> Native apps install via CLI in < 2 seconds. GMS apps run inside the GBox container.

### Architecture: Dual-Layer Ecosystem

```
+--------------------------------------------------------------+
|                    EMUI 10.1 Native Layer                    |
|  - Headless `adb install -r -d <app.apk>`                    |
|  - Download via `apkeep` (F-Droid, APKPure) or GitHub CLI    |
|  - Shizuku elevated server for rootless system management    |
|  - Lawnchair 14, DevCheck, Weylus, DroidCam, Aurora Store    |
+--------------------------------------------------------------+
                               |
                               v
+--------------------------------------------------------------+
|             GBox Virtual Container (com.vlite.sdk)           |
|  - Full sandboxed Google Play Services & Google Play Store   |
|  - Google Health Connect (`com.google.android.apps.healthdata`|
|  - Google Fit (`com.google.android.apps.fitness`)            |
|  - Shortcuts exposed directly on Lawnchair home screen       |
+--------------------------------------------------------------+
```

### 1-Command Native App Installation (`matepad install` or `apkeep`)
Download and install directly from CLI:
```bash
# Using the declarative helper:
matepad install <package_id_or_path.apk>

# Manual CLI download & install:
apkeep -d f-droid -a <package_id> /tmp/apks/
# OR for APKPure:
apkeep -d apk-pure -a <package_id> -o 'acknowledge_dangers=true' /tmp/apks/

# Instant headless install:
adb -s QBK6R20825000010 install -r -d /tmp/apks/<package_id>.apk
```

### Elevated Permission Granting
Grant diagnostic and runtime permissions directly over ADB without touching the screen:
```bash
adb -s QBK6R20825000010 shell pm grant <package> android.permission.BATTERY_STATS
adb -s QBK6R20825000010 shell pm grant <package> android.permission.DUMP
adb -s QBK6R20825000010 shell pm grant <package> android.permission.PACKAGE_USAGE_STATS
adb -s QBK6R20825000010 shell cmd appops set <package> <op_name> allow
```

---

## 4. Battery Preservation & Thermal Guardrails

> [!CAUTION]
> **DO NOT ENABLE `com.google.android.googlequicksearchbox`!**
> On EMUI 10 without Google framework, Google Search enters a runaway 100% CPU thread spinloop that rapidly overheats the Kirin 990 and drains the battery even while plugged in. Keep it disabled:
> `adb shell pm disable-user --user 0 com.google.android.googlequicksearchbox`

- **Do NOT install Huawei Health (`com.huawei.health`)**: Kept intentionally off the tablet. Google Health Connect and Google Fit are used inside GBox instead.
- **Battery Health Query**:
  ```bash
  adb shell dumpsys battery
  # Check status: 5 (Full), 2 (Charging); temperature (div by 10 for °C)
  ```
- **CPU & Process Load**:
  ```bash
  adb shell "top -b -n 1 -m 5"
  ```

---

## 5. Shizuku Privilege Server

Shizuku provides elevated Android API access via `adb` permission delegation.

- **Check if running**:
  ```bash
  adb shell ps -ef | grep shizuku_server
  ```
- **Start after tablet reboot**:
  ```bash
  just android::start-shizuku
  # OR:
  matepad shizuku
  ```

---

## 6. The `matepad` Helper CLI

Declared in `nix-config/modules/nixos/android.nix`:

```bash
matepad status     # Live battery, thermals, tunnels, Shizuku, and spinloop guardrail
matepad tunnels    # Restore all reverse tunnels (1701, 3389, 4747)
matepad shizuku    # Verify or boot Shizuku privileged server
matepad install    # Install APK directly or fetch from repo via apkeep
matepad devcheck   # Grant elevated diagnostic permissions and open DevCheck
```
