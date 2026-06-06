# Watch Wandrer

A standalone exploration app for **HarmonyOS wearables** that displays **Wandrer.earth** road overlays (traveled vs. untraveled) directly on your watch.

## 🚀 Mission
Enable phone-free exploration by rendering offline vector map tiles with real-time GPS tracking on HarmonyOS smartwatches.

## ✨ Key Features
- **Standalone Maps**: GPU-accelerated vector tiles rendered via `@kit.ArkGraphics2D`
- **Phone-Free Exploration**: Offline map tiles and standalone GPS breadcrumb recording
- **Glanceable Stats**: Real-time "New Roads" and distance via HarmonyOS **LiveView capsules**
- **Optimized Rendering**: 60fps map rendering on wearable hardware

## 🎯 Getting Started

### Quick Start (Emulator - No Hardware Needed)

```bash
# 1. Install DevEco Studio
# Download from: https://developer.huawei.com/consumer/en/deveco-studio/

# 2. Follow emulator setup guide
See EMULATOR_SETUP.md for complete instructions

# 3. Process your Wandrer data
cd phone-app/processor
npm install
npx ts-node src/processor.ts ../../example/wandrer-pinxton-example.kml ../../data/tiles

# 4. Open watch-app in DevEco Studio
# File → Open → /path/to/watch-wandrer/watch-app

# 5. Run on emulator
# Click Run ▶️ button
```

**New to this project?** Start with [`EMULATOR_SETUP.md`](./EMULATOR_SETUP.md) - develop and test without any physical watch.

## 📁 Repository Structure
- **`/watch-app`**: ArkTS wearable application (HarmonyOS NEXT API 13)
- **`/phone-app/processor`**: Node.js tool to convert Wandrer KML → optimized vector tiles
- **`/phone-app/companion`**: React Native sync dashboard (future)
- **`/data/tiles`**: Processed tile data
- **`/example`**: Sample Wandrer KML data (Pinxton, UK)

## 🏗 Tech Stack
- **Watch OS**: HarmonyOS NEXT (API 13)
- **Language**: ArkTS (Watch), TypeScript (Processor)
- **Rendering**: Drawing SDK (`@kit.ArkGraphics2D`)
- **Kits**: LiveView Kit, Location Kit, Ability Kit
- **Development**: DevEco Studio 5.0+

## 🖥️ Compatible Devices

### Development (Emulator)
- ✅ DevEco Studio built-in wearable emulator (FREE)

### Physical Devices (HarmonyOS Smartwatches)
- ✅ HUAWEI WATCH 4 / 4 Pro
- ✅ HUAWEI WATCH GT 5 / GT 5 Pro
- ✅ HUAWEI WATCH GT 3 / GT 3 Pro
- ✅ HUAWEI WATCH Ultimate
- ❌ WATCH FIT series (runs LiteOS, not full HarmonyOS)

## 📚 Documentation

- **[EMULATOR_SETUP.md](./EMULATOR_SETUP.md)** - Start here! Develop without hardware
- **[PROTOTYPE_README.md](./PROTOTYPE_README.md)** - Original prototype notes
- **`/docs/archive/`** - Archived hardware-specific guides

## 🛣️ Roadmap

- [x] Vector tile processor (KML → JSON tiles)
- [x] GPU-accelerated map renderer
- [x] Emulator development workflow
- [ ] Real-time GPS tracking integration
- [ ] LiveView capsule implementation
- [ ] Companion phone app for syncing
- [ ] AppGallery publication

## 🤝 Contributing

This is a personal exploration project, but suggestions and ideas are welcome via issues.

## 📄 License

MIT License - See LICENSE file for details
