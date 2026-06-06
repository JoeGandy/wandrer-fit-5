# Archived Documentation

This folder contains documentation that was created for specific hardware setups but is no longer the recommended development path.

## Current Approach

**Use the emulator** - See [`/EMULATOR_SETUP.md`](../../EMULATOR_SETUP.md) for the recommended development workflow.

## Archived Files

### `ARCH_TESTING_GUIDE.md`
- **Created for**: Physical HUAWEI WATCH FIT 5 on Arch Linux
- **Why archived**: WATCH FIT 5 runs LiteOS (not full HarmonyOS) and doesn't support custom app development
- **Alternative**: Use emulator or buy compatible HarmonyOS smartwatch (GT 5, WATCH 4, etc.)

### `CERTIFICATE_SETUP.md`
- **Created for**: AppGallery Connect certificate setup for physical device deployment
- **Why archived**: Not needed for emulator development
- **When needed**: Only when deploying to real HarmonyOS smartwatch hardware

## If You Need Physical Hardware

If you decide to test on real hardware later:

1. **Compatible devices**: WATCH GT 5, WATCH 4 Pro, WATCH GT 3, WATCH Ultimate
2. **Certificate setup**: Refer to `CERTIFICATE_SETUP.md` for AppGallery Connect configuration
3. **Connection**: Wi-Fi debugging is primary method for HarmonyOS NEXT watches

## Questions?

See the main [`README.md`](../../README.md) for current project status and [`EMULATOR_SETUP.md`](../../EMULATOR_SETUP.md) for getting started.
