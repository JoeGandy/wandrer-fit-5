# Watch Wandrer - Emulator Development Setup

This guide will get you developing Watch Wandrer using the **DevEco Studio emulator** - no physical watch required.

## Why Emulator First?

- **Free** - No hardware purchase needed
- **Fast iteration** - Instant deployment and testing
- **Full HarmonyOS support** - All APIs available
- **Debug tools** - Built-in profiler, inspector, logs
- **Buy hardware later** - Only if you need real GPS/sensors

## Prerequisites

- **Linux** (Arch, Ubuntu, etc.) or macOS or Windows
- **16GB RAM minimum** (emulator is resource-intensive)
- **20GB free disk space** for SDK and emulator images
- **Java 17+** installed

## Step 1: Install DevEco Studio

### Download

Visit: https://developer.huawei.com/consumer/en/deveco-studio/

Download the **Linux** version (or your OS).

### Install on Arch Linux

```bash
# Extract DevEco Studio
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

# Launch
/opt/deveco-studio/bin/deveco-studio.sh
```

### First Launch Setup

1. **Welcome screen** - Click "Next"
2. **SDK Location** - Accept default (`~/Huawei/Sdk/`) or choose custom
3. **Download SDK**:
   - ✅ HarmonyOS SDK (API 13)
   - ✅ Previewer
   - ✅ Emulator
   - ✅ Command-line tools
4. **Sign in** with your Huawei ID (free account)
5. Wait for downloads to complete (~5-10 minutes)

## Step 2: Create Wearable Emulator

### Create AVD (Android Virtual Device)

1. In DevEco Studio, go to **Tools** → **Device Manager**
2. Click **Create Device**
3. Select:
   - **Device Type**: `Wearable`
   - **Device**: `HUAWEI WATCH` or `Generic Wearable`
   - **System Image**: `HarmonyOS NEXT API 13` (download if needed)
   - **Screen**: `466x466` (round) or `480x480`
4. Click **Finish**

### Start Emulator

1. In Device Manager, click ▶️ **Start** next to your emulator
2. Wait for emulator to boot (~30-60 seconds)
3. You should see a virtual watch screen

**Tip**: Keep the emulator running while developing for faster iteration.

## Step 3: Open Watch Wandrer Project

```bash
# Open DevEco Studio
/opt/deveco-studio/bin/deveco-studio.sh

# File → Open → Select project directory
/home/joe/projects/watch-wandrer/watch-app
```

Wait for Gradle sync to complete.

## Step 4: Configure Project for Emulator

The project is already configured for wearables. Verify settings:

### Check `module.json5`

```json5
{
  "module": {
    "deviceTypes": [
      "wearable"  // ✅ Correct
    ]
  }
}
```

### Check `build-profile.json5`

```json5
{
  "app": {
    "compileSdkVersion": 13,
    "compatibleSdkVersion": 13
  }
}
```

## Step 5: Run on Emulator

### Using Previewer (Fastest)

1. Open `entry/src/main/ets/pages/Index.ets`
2. Click **Previewer** button (top-right)
3. See instant UI preview

**Previewer** is great for UI work but doesn't support:
- GPS/Location
- File system
- Background services

### Using Emulator (Full Testing)

1. Ensure emulator is running (Device Manager)
2. Select emulator from device dropdown (top toolbar)
3. Click **Run** ▶️ button
4. App builds and installs to emulator
5. App launches automatically

**First run** may take 2-3 minutes to build. Subsequent runs are faster.

## Step 6: Load Map Tiles into Emulator

The emulator has its own file system. Push tiles using `hdc`:

```bash
# Add hdc to PATH
export PATH="$HOME/Huawei/Sdk/harmonyos/toolchains:$PATH"

# List emulator devices
hdc list targets
# Output: emulator-5554 (or similar)

# Create tile directory on emulator
hdc shell mkdir -p /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/

# Push tiles to emulator
hdc file send /home/joe/projects/watch-wandrer/data/tiles/15/ \
  /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/

# Verify
hdc shell ls -la /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/
```

## Step 7: Debug and Test

### View Logs

```bash
# Real-time logs
hdc hilog | grep "WatchWandrer"

# Or use DevEco Studio's built-in log viewer
# View → Tool Windows → HiLog
```

### Debug Mode

1. Set breakpoints in code (click left margin)
2. Click **Debug** 🐛 button instead of Run
3. App pauses at breakpoints
4. Inspect variables, step through code

### Simulate GPS Location

The emulator doesn't have real GPS, but you can simulate location:

1. In Device Manager, click **⋮** (more options) on running emulator
2. Select **Extended Controls**
3. Go to **Location** tab
4. Enter coordinates or load GPX route
5. Click **Send**

**For Wandrer testing**: Use coordinates in your tile area (e.g., Pinxton, UK).

## Step 8: Iterate Quickly

Development workflow:

```bash
# 1. Make code changes in DevEco Studio

# 2. Click Run (or Ctrl+R)
#    - Incremental build (fast)
#    - Auto-install to emulator
#    - Auto-launch app

# 3. Test on emulator

# 4. Check logs
hdc hilog | grep "WatchWandrer"

# 5. Repeat
```

## Emulator Limitations

The emulator is excellent but has some limitations:

| Feature | Emulator | Real Watch |
|---------|----------|------------|
| UI/UX Testing | ✅ Perfect | ✅ Perfect |
| Map Rendering | ✅ Works | ✅ Works |
| GPS Tracking | ⚠️ Simulated | ✅ Real |
| Performance | ⚠️ Slower | ✅ Native |
| Battery Impact | ❌ N/A | ✅ Real |
| Digital Crown | ❌ No | ✅ Yes |
| Sensors (HR, etc.) | ⚠️ Simulated | ✅ Real |

**Bottom line**: Emulator is perfect for 90% of development. Buy real hardware only when you need actual GPS tracking or sensor data.

## Troubleshooting

### Emulator won't start

```bash
# Check virtualization enabled
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0

# Check KVM
ls -la /dev/kvm
# Should exist

# Add user to kvm group
sudo usermod -aG kvm $USER
# Log out and back in
```

### "hdc not found"

```bash
# Add to PATH
echo 'export PATH="$HOME/Huawei/Sdk/harmonyos/toolchains:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
hdc -v
```

### Emulator is slow

- Allocate more RAM in emulator settings (4GB+)
- Close other applications
- Use Previewer for UI-only work
- Consider faster CPU or enable hardware acceleration

### Build errors

```bash
# Clean and rebuild
cd /home/joe/projects/watch-wandrer/watch-app
./hvigorw clean
./hvigorw assembleHap --mode module -p product=default
```

## Next Steps

Once you're comfortable with emulator development:

1. **Process real Wandrer data** - See `phone-app/processor/`
2. **Test map rendering** - Load your actual explored roads
3. **Implement GPS tracking** - Use simulated routes
4. **Build companion app** - React Native sync dashboard
5. **Consider real hardware** - If you need actual GPS testing

## Quick Reference

```bash
# Start emulator
# Device Manager → Start

# Deploy to emulator
# Click Run ▶️ in DevEco Studio

# View logs
hdc hilog | grep "WatchWandrer"

# Push files to emulator
hdc file send <local-path> <emulator-path>

# Shell access
hdc shell

# Restart emulator
# Device Manager → Stop → Start
```

## Resources

- [DevEco Studio Docs](https://developer.huawei.com/consumer/en/deveco-studio/)
- [HarmonyOS Wearable Development](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/start-overview)
- [Emulator Guide](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-emulator)
- [ArkTS Language](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/arkts-get-started)

---

**You're now ready to develop Watch Wandrer without any physical hardware!** 🎉
