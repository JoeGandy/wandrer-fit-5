# Watch Wandrer Prototype — HarmonyOS 6.1 NEXT Edition

This prototype is optimized for **HUAWEI WATCH FIT 5** running **HarmonyOS 6.1+ (API 13)**.

**Core Design: 100% Standalone Outdoors.** 
You do **NOT** need to carry your phone while exploring. The phone is used only for initial data setup and post-activity syncing.

---

## 1. Process Wandrer Data
Process your KML/KMZ exports into optimized tiles:
```bash
cd phone-app/processor
npm install
npx ts-node src/processor.ts <path-to-kml> ../../data/tiles
```
*Tiles for Pinxton are pre-generated in `./data/tiles/15/`.*

---

## 2. Load the Watch App (HUAWEI WATCH FIT 5)
The app uses the **Drawing SDK** for GPU-accelerated map rendering.

### Standalone Capabilities
- **Internal GPS**: Uses the FIT 5's built-in GNSS.
- **Local Storage**: All map tiles and recorded paths are stored on the watch.
- **Offline Rendering**: No internet or phone connection required for the map.

### macOS Setup
1. **Download**: [DevEco Studio 5.0+ for Mac](https://developer.huawei.com/consumer/en/deveco-studio/) (Choose Intel or ARM/Apple Silicon version).
2. **Install**: Drag to Applications.
3. **Open Project**: Import the `@/watch-app` folder.
4. **HDC (Tile Pushing)**:
   The `hdc` tool is located inside your SDK. You may need to add it to your PATH:
   ```bash
   # Add this to your ~/.zshrc or run in terminal
   export PATH=$PATH:~/Library/Huawei/Sdk/harmonyos/v5/toolchains
   ```
5. **Push Tiles**:
   ```bash
   # Create tile directory on watch
   hdc shell mkdir -p /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/
   
   # Send processed tiles
   hdc file send ./data/tiles/15/ /data/app/el2/100/base/com.joe.watchwandrer/files/tiles/15/
   ```

### Linux (Arch) Setup (Alternative)
DevEco Studio has a **native Linux version**. Do **NOT** use Wine.
... (Rest of Linux section) ...

---

## 3. Load the Companion App (Phone Sync Hub)
The companion app acts as your data manager. Use it before you leave or after you return.

### Steps
1. Install dependencies:
   ```bash
   cd phone-app/companion
   npm install
   ```
2. Start Expo:
   ```bash
   npx expo start
   ```
3. Open **Expo Go** on your phone and scan the QR code.

---

## 4. Modern Features (HarmonyOS 6.1)
- **Standalone Exploration**: Full vector map rendering without phone tethering.
- **High-Perf Map**: GPU-accelerated rendering via `DrawingRenderingContext`.
- **Physical Crown**: Use the Digital Crown to zoom.
- **LiveView Capsule**: Dynamic status at the top of the watch system UI.
- **Background Persistence**: Tracking continues even when the screen is off.

---

## 5. Prototype Controls
- **Watch (Standalone Mode)**:
  - **Record Button**: Starts standalone GPS tracking and path logging.
  - **Map Tab**: Interact with offline Wandrer overlays.
- **Phone (Sync Hub Mode)**:
  - **Scan Files**: Prepares data for the next exploration.
  - **Sync to Watch**: Pushes tiles to watch storage.
  - **Import Activity**: Retrieves your recorded path after you return.
