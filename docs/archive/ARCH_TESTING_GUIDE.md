# Testing Watch Wandrer on Arch Linux with HUAWEI WATCH FIT 5

This guide covers the complete setup for testing the Watch Wandrer app on your Arch Linux system with the HUAWEI WATCH FIT 5.

## Prerequisites

- HUAWEI WATCH FIT 5 running HarmonyOS 6.1+ (API 13)
- Arch Linux system
- USB cable for watch connection
- Developer mode enabled on watch

## Step 1: Enable Developer Mode on WATCH FIT 5

1. On your watch, go to: **Settings** → **Huawei Watch Rates** → **Software Version**
2. Tap **Software Version** **5-7 times** continuously until you see "Developer Options are enabled" message
3. Go back to **Settings** → **System** → **Developer Options**
4. Enable:
   - **HDC debugging**
   - **Debug via Wi-Fi** (you'll see an IP address like `192.168.x.x:5555` - note this down)

**Note:** HarmonyOS NEXT primarily uses Wi-Fi debugging. USB debugging may be limited or require the watch and PC to be on the same network. The IP address shown in "Debug via Wi-Fi" will be used to connect via `hdc`.

## Step 2: Install DevEco Studio (Linux Native)

DevEco Studio is required to build and deploy HarmonyOS apps.

### Download and Install

```bash
# Download DevEco Studio for Linux from:
# https://developer.huawei.com/consumer/en/deveco-studio/

# Extract to /opt (or your preferred location)
sudo mkdir -p /opt/deveco-studio
sudo tar -xzf DevEcoStudio-*.tar.gz -C /opt/deveco-studio --strip-components=1

# Create desktop entry (optional)
cat > ~/.local/share/applications/deveco-studio.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=DevEco Studio
Icon=/opt/deveco-studio/bin/deveco-studio.png
Exec=/opt/deveco-studio/bin/deveco-studio.sh
Comment=HarmonyOS Development IDE
Categories=Development;IDE;
Terminal=false
EOF
```

### First Launch Setup

1. Launch DevEco Studio: `/opt/deveco-studio/bin/deveco-studio.sh`
2. Follow the setup wizard to download:
   - HarmonyOS SDK (API 13)
   - Build tools
   - Command-line tools (includes `hdc`)
3. SDK will be installed to: `~/Huawei/Sdk/` (default)

### Add `hdc` to PATH

```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$HOME/Huawei/Sdk/harmonyos/toolchains:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
hdc -v
```

## Step 3: Configure USB Permissions (udev Rules)

Create udev rules to allow non-root access to your HUAWEI watch.

```bash
# Create udev rule for HUAWEI devices
sudo tee /etc/udev/rules.d/51-huawei-watch.rules > /dev/null <<EOF
# HUAWEI WATCH FIT 5 - HarmonyOS Development
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", ATTR{idProduct}=="*", SYMLINK+="android_adb"

# Alternative vendor IDs (if needed)
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
EOF

# Add your user to plugdev group
sudo usermod -aG plugdev $USER

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# You may need to log out and back in for group changes to take effect
```

## Step 4: Connect and Verify Watch Connection

HarmonyOS NEXT watches primarily use **Wi-Fi debugging**. You have two connection options:

### Option A: Wi-Fi Connection (Recommended)

```bash
# Ensure watch and PC are on the same Wi-Fi network
# OR enable a hotspot on your PC and connect the watch to it

# Get the IP address from watch:
# Settings → System → Developer Options → Debug via Wi-Fi
# Note the IP (e.g., 192.168.1.100:5555)

# Connect via hdc
hdc tconn 192.168.1.100:5555

# Verify connection
hdc list targets
# Should show: 192.168.1.100:5555
```

### Option B: USB Connection (If Supported)

```bash
# Connect watch via USB and unlock it
# Accept the "Allow HDC debugging" prompt on the watch

# Check if device is detected
lsusb | grep -i huawei

# Start hdc server and list devices
hdc kill
hdc start
hdc list targets

# You should see your watch's serial number or IP
```

### Troubleshooting Connection

If `hdc list targets` shows nothing:

**For Wi-Fi Connection:**
```bash
# Verify both devices are on same network
# Check watch IP hasn't changed
# Settings → System → Developer Options → Debug via Wi-Fi

# Try reconnecting
hdc kill
hdc start
hdc tconn <WATCH_IP>:5555

# Check if hdc server is running
ps aux | grep hdc
```

**For USB Connection:**
```bash
# Check USB connection
lsusb

# Check if watch shows HDC debugging notification

# Try different USB ports or cables

# Check dmesg for USB events
dmesg | tail -20

# Restart hdc server
hdc kill
hdc start
```

## Step 5: Build the Watch App

### Option A: Using DevEco Studio (GUI)

1. Open DevEco Studio
2. **File** → **Open** → Select `/home/joe/projects/watch-wandrer/watch-app`
3. Wait for Gradle sync to complete
4. Click **Build** → **Build Hap(s)/App(s)** → **Build Hap(s)**
5. Built `.hap` file will be in: `watch-app/entry/build/default/outputs/default/`

### Option B: Using Command Line (hvigorw)

```bash
cd /home/joe/projects/watch-wandrer/watch-app

# Clean build
./hvigorw clean

# Build HAP package
./hvigorw assembleHap --mode module -p product=default

# HAP location: entry/build/default/outputs/default/entry-default-signed.hap
```

## Step 6: Install App on Watch

```bash
cd /home/joe/projects/watch-wandrer/watch-app

# Install the HAP package
hdc install entry/build/default/outputs/default/entry-default-signed.hap

# Or use the helper script (see below)
./scripts/deploy-watch.sh
```

## Step 7: Push Map Tiles to Watch

The app requires map tiles to be stored in the watch's data directory.

```bash
# Create tile directory on watch
hdc shell mkdir -p /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/

# Push tiles from your computer
hdc file send /home/joe/projects/watch-wandrer/data/tiles/15/ /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/

# Verify tiles were copied
hdc shell ls -la /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/

# Or use the helper script
./scripts/push-tiles.sh
```

## Step 8: Launch and Test

```bash
# Launch the app
hdc shell aa start -a EntryAbility -b com.joe.watchwandrer

# View logs in real-time
hdc hilog | grep "WatchWandrer"

# Or use the helper script
./scripts/watch-logs.sh
```

## Common Testing Commands

```bash
# Uninstall app
hdc uninstall com.joe.watchwandrer

# Reinstall (clean install)
hdc uninstall com.joe.watchwandrer
hdc install entry/build/default/outputs/default/entry-default-signed.hap

# Clear app data
hdc shell rm -rf /data/app/el2/100/base/com.joe.watchwandrer/files/*

# Take screenshot from watch
hdc shell snapshot_display -f /data/local/tmp/screenshot.png
hdc file recv /data/local/tmp/screenshot.png ./screenshot.png

# Check app permissions
hdc shell bm dump -n com.joe.watchwandrer

# Force stop app
hdc shell aa force-stop com.joe.watchwandrer
```

## Debugging Tips

### View All Logs
```bash
# All system logs
hdc hilog

# Filter by app tag
hdc hilog | grep "WatchWandrer"

# Clear log buffer
hdc shell hilog -r
```

### Check GPS/Location
```bash
# Verify location permissions
hdc shell bm dump -n com.joe.watchwandrer | grep -i location

# Test GPS (requires outdoor location)
# Watch the logs while using the app's Record feature
```

### Performance Monitoring
```bash
# Monitor CPU/Memory usage
hdc shell top | grep watchwandrer

# Check battery impact
hdc shell dumpsys battery
```

## Known Issues on Arch Linux

1. **hdc not found**: Ensure SDK path is in your PATH and you've sourced your shell config
2. **Permission denied**: Check udev rules and ensure you're in the `plugdev` group
3. **Device not detected**: Try different USB ports, restart hdc server, or reboot watch
4. **Build failures**: Ensure you have Java 17+ installed (`java -version`)

## Quick Reference

| Task | Command |
|------|---------|
| List devices | `hdc list targets` |
| Install app | `hdc install <path-to-hap>` |
| Uninstall app | `hdc uninstall com.joe.watchwandrer` |
| View logs | `hdc hilog \| grep WatchWandrer` |
| Push files | `hdc file send <local> <remote>` |
| Pull files | `hdc file recv <remote> <local>` |
| Shell access | `hdc shell` |
| Restart hdc | `hdc kill && hdc start` |

## Next Steps

1. Process your Wandrer KML data (see `PROTOTYPE_README.md`)
2. Build and install the watch app
3. Push map tiles to the watch
4. Test the app outdoors with GPS enabled
5. Use the companion phone app for syncing (optional)

For more details on the app architecture and features, see `README.md` and `PROTOTYPE_README.md`.
