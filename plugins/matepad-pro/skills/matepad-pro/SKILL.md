---
name: matepad-pro
description: >-
  Manual-only operational guide for the Huawei MatePad Pro (MRX-W09) fleet tablet.
  Activate ONLY when the user explicitly requests to interact with, inspect, or manage
  the MatePad Pro tablet. Do not load automatically for general Android, ADB, or fleet tasks.
disable-model-invocation: true
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

## 2. Fleet Roles & Tunnels

The tablet serves three roles in the `kleinbem` workstation setup, each over one ADB tunnel:

1. **Secondary Display & Stylus Digitizer (Weylus)**: reverse tunnel on port `1701`
   (`adb -s QBK6R20825000010 reverse tcp:1701 tcp:1701`).
2. **Remote Desktop / RDP Extended Display**: reverse tunnel on port `3389` via GNOME Remote
   Desktop (`adb -s QBK6R20825000010 reverse tcp:3389 tcp:3389`).
3. **Webcam & Microphone (DroidCam)**: forward tunnel on port `4747` feeding `/dev/video10`
   (v4l2loopback) (`adb -s QBK6R20825000010 forward tcp:4747 tcp:4747`).

`matepad tunnels` sets up all three. **Desk Companion Mode**, `just android::tablet-desk` in
`nix-config` (runs `android-config`'s recipe), sets up all three, keeps the screen on while
plugged in and starts Shizuku.

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
|  - Native Companion Bridge APKs (`org.kleinbem.gbox.*`)      |
+--------------------------------------------------------------+
```

### GBox Companion Bridge APKs (App Drawer & Search Integration)

Standard Android launchers (such as Lawnchair 14) populate the **App Drawer** and **Global Search Bar** strictly via Android's `LauncherApps` / `PackageManager.queryIntentActivities()` APIs. Pinned shortcuts created directly by GBox are deep shortcuts (`ShortcutInfo`, type 6) placed strictly onto workspace cells and will **never** appear in the All Apps drawer or search bar.

To make any GBox app searchable, filterable, and cataloged natively:
- A featherweight companion APK (`org.kleinbem.gbox.<name>`) is compiled and installed into the Android OS layer.
- **Activity**: Transparent activity that fires `com.gbox.android.action.LAUNCH_APP` with `setPackage("com.gbox.android")` and extra `packageName = <target_gbox_package>`, then immediately finishes (`finish()`).
- **Overhead**: Zero runtime memory or background battery consumption.
- **Icons**: Official 512x512 adaptive/mipmap icons across all densities (`mdpi` through `xxxhdpi`).
- **Inventory**: YouTube (`org.kleinbem.youtube`), Gmail, Google Calendar, Google Drive, Google Keep, Google Meet, Google Chat, Google Fit, Health Connect, Instagram, Family Link, Google Play Store (`org.kleinbem.gbox.*`).
- Generator script: `/tmp/build_gbox_bridges.py`.

### 1-Command Native App Installation (`matepad install` or `apkeep`)
Download and install directly from CLI:
```bash
# Using the declarative helper:
matepad install <package_id_or_path.apk>

# Manual CLI download & install (apkeep needs an existing output directory):
mkdir -p /tmp/apks
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
> `adb -s QBK6R20825000010 shell pm disable-user --user 0 com.google.android.googlequicksearchbox`
> (no-link: Google doesn't support the app without Google Play Services, so there is no upstream to report to.)

- **Do NOT install Huawei Health (`com.huawei.health`)**: Kept intentionally off the tablet. Google Health Connect and Google Fit are used inside GBox instead.
- **Battery Health Query**:
  ```bash
  adb -s QBK6R20825000010 shell dumpsys battery
  # Check status: 5 (Full), 2 (Charging); temperature (div by 10 for °C)
  ```
- **CPU & Process Load**:
  ```bash
  adb -s QBK6R20825000010 shell "top -b -n 1 -m 5"
  ```

---

## 5. Shizuku Privilege Server & USB Auto-Start

Shizuku provides elevated Android API access via `adb` permission delegation.

- **Automatic Start on USB Plug**:
  Configured in `nix-config/modules/nixos/android.nix` via udev rule and `shizuku-auto.service`. Whenever the tablet or phone is connected or reboots over USB, Shizuku is automatically booted in the background.
- **Check if running**:
  ```bash
  adb -s QBK6R20825000010 shell ps -ef | grep shizuku_server
  ```
- **Manual Start over ADB**:
  ```bash
  just android::start-shizuku
  # OR:
  matepad shizuku
  ```

---

## 6. The `matepad` Helper CLI

Declared in `nix-config/modules/home-manager/android.nix`:

```bash
matepad status     # Live battery, thermals, tunnels, Shizuku, and spinloop guardrail
matepad tunnels    # Restore all companion tunnels (1701 Weylus, 3389 RDP, 4747 DroidCam)
matepad shizuku    # Verify or boot Shizuku privileged server
matepad install    # Install APK directly or fetch from repo via apkeep
matepad devcheck   # Grant elevated diagnostic permissions and open DevCheck
```
