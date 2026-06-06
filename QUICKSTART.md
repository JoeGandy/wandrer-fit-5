# Watch Wandrer - Quick Start Guide

Get up and running with Watch Wandrer in **under 30 minutes** using the emulator.

## Prerequisites

- Linux, macOS, or Windows
- 16GB RAM minimum
- 20GB free disk space
- Java 17+ installed

## Step 1: Install DevEco Studio (10 minutes)

```bash
# Download from:
https://developer.huawei.com/consumer/en/deveco-studio/

# Linux installation:
sudo mkdir -p /opt/deveco-studio
sudo tar -xzf DevEcoStudio-*.tar.gz -C /opt/deveco-studio --strip-components=1
/opt/deveco-studio/bin/deveco-studio.sh

# First launch:
# 1. Accept SDK location (~/Huawei/Sdk/)
# 2. Download HarmonyOS SDK API 13 + Emulator
# 3. Sign in with Huawei ID (create free account if needed)
```

## Step 2: Create Emulator (5 minutes)

```bash
# In DevEco Studio:
# Tools → Device Manager → Create Device
# - Device Type: Wearable
# - Device: HUAWEI WATCH or Generic Wearable
# - System Image: HarmonyOS NEXT API 13
# - Screen: 466x466 (round)
# Click Finish

# Start emulator:
# Device Manager → Click ▶️ Start
# Wait ~30 seconds for boot
```

## Step 3: Open Project (2 minutes)

```bash
# In DevEco Studio:
# File → Open → Select:
/home/joe/projects/watch-wandrer/watch-app

# Wait for Gradle sync to complete
```

## Step 4: Process Map Data (5 minutes)

```bash
cd /home/joe/projects/watch-wandrer/phone-app/processor

# Install dependencies
npm install

# Process example Wandrer data
npx ts-node src/processor.ts \
  ../../example/wandrer-pinxton-example.kml \
  ../../data/tiles

# You should see: "✅ Generated X tiles"
```

## Step 5: Run on Emulator (5 minutes)

```bash
# In DevEco Studio:
# 1. Ensure emulator is running (green dot in Device Manager)
# 2. Select emulator from device dropdown (top toolbar)
# 3. Click Run ▶️ button
# 4. Wait for build (~2-3 minutes first time)
# 5. App launches on emulator automatically
```

## Step 6: Load Map Tiles (3 minutes)

```bash
# Add hdc to PATH
export PATH="$HOME/Huawei/Sdk/harmonyos/toolchains:$PATH"

# Push tiles to emulator
hdc shell mkdir -p /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/
hdc file send /home/joe/projects/watch-wandrer/data/tiles/15/ \
  /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/

# Verify
hdc shell ls /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/
```

## Step 7: Test the App

```bash
# On the emulator:
# - You should see the map with Wandrer overlays
# - Tap to interact
# - Swipe to navigate

# View logs:
hdc hilog | grep "WatchWandrer"
```

## 🎉 Success!

You now have Watch Wandrer running on the emulator. Next steps:

- **Customize**: Edit code in `watch-app/entry/src/main/ets/`
- **Process your data**: Replace example KML with your Wandrer export
- **Iterate**: Make changes → Click Run → Test
- **Debug**: Set breakpoints and use Debug 🐛 button

## Common Issues

### "hdc not found"
```bash
export PATH="$HOME/Huawei/Sdk/harmonyos/toolchains:$PATH"
```

### Emulator won't start
```bash
# Check virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo  # Should be > 0

# Add to kvm group
sudo usermod -aG kvm $USER
# Log out and back in
```

### Build errors
```bash
cd watch-app
./hvigorw clean
./hvigorw assembleHap --mode module -p product=default
```

## Need More Help?

- **Full emulator guide**: [`EMULATOR_SETUP.md`](./EMULATOR_SETUP.md)
- **Project overview**: [`README.md`](./README.md)
- **Tile processor**: [`phone-app/processor/README.md`](./phone-app/processor/README.md)

---

**Total time**: ~30 minutes from zero to running app! 🚀
