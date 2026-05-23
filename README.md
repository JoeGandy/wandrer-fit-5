# Watch Wandrer

A standalone exploration app for the **HUAWEI WATCH FIT 5** (HarmonyOS 6.1 NEXT).

## 🚀 Mission
Enable phone-free exploration by displaying **Wandrer.earth** road overlays (traveled vs. untraveled) directly on the watch.

## ✨ Key Features
- **Standalone Maps**: GPU-accelerated vector tiles rendered via `@kit.ArkGraphics2D`.
- **Phone-Free Exploration**: Offline map tiles and standalone GPS breadcrumb recording.
- **Glanceable Stats**: Real-time "New Roads" and distance via HarmonyOS **LiveView capsules**.
- **Hardware Optimized**: Digital Crown support for zooming and 60fps rendering.

## 📁 Repository Map
- `/watch-app`: ArkTS application for HarmonyOS NEXT (API 13).
- `/phone-app/processor`: Node.js tool to convert Wandrer KML data into optimized watch tiles.
- `/phone-app/companion`: React Native (Expo) dashboard for syncing tiles and importing activities.

## 🛠 Setup & Deployment
See [PROTOTYPE_README.md](./PROTOTYPE_README.md) for detailed deployment instructions for Linux (Arch) and macOS.

## 🏗 Tech Stack
- **OS**: HarmonyOS 6.1 (NEXT)
- **Language**: ArkTS (Watch), TypeScript (Processor), TSX (Companion)
- **Kits**: Drawing SDK, LiveView Kit, Location Kit, Ability Kit
