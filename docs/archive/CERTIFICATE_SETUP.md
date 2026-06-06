# Certificate Setup for WATCH FIT 5 Development

Before you can deploy custom apps to your HUAWEI WATCH FIT 5, you need to set up debug certificates through AppGallery Connect. This is a **one-time setup** required for HarmonyOS development.

## Why Certificates Are Required

HarmonyOS requires all apps to be signed, even during development. Debug certificates allow you to:
- Install apps directly to your watch via `hdc`
- Test without publishing to AppGallery
- Develop and iterate quickly

## Prerequisites

- HUAWEI Developer Account (free): https://developer.huawei.com
- DevEco Studio installed
- Watch connected and UDID obtained

## Step 1: Get Your Watch's UDID

The UDID (Unique Device Identifier) is required to register your watch for development.

```bash
# Connect watch (via Wi-Fi or USB)
hdc tconn <WATCH_IP>:5555

# Get UDID
hdc shell bm get -u

# Output will be something like:
# udid of current device is: 1234567890ABCDEF1234567890ABCDEF12345678
```

**Save this UDID** - you'll need it in the next steps.

## Step 2: Create AppGallery Connect Project

1. Go to [AppGallery Connect](https://developer.huawei.com/consumer/en/service/josp/agc/index.html)
2. Sign in with your HUAWEI ID
3. Click **My projects** → **Add project**
4. Enter project details:
   - **Project name**: `WatchWandrer` (or your choice)
   - **Data processing location**: Choose your region
5. Click **Add**

## Step 3: Generate Certificate Signing Request (CSR)

In DevEco Studio:

1. Go to **Build** → **Generate Key and CSR**
2. Fill in the form:
   - **Key Alias**: `watch-wandrer-debug`
   - **Password**: Create a strong password (save it!)
   - **Validity**: 25 years
   - **Organization**: Your name or company
   - **Country**: Your country code (e.g., `GB`)
3. Click **OK**
4. Save the files:
   - **Keystore file** (`.p12`): Save to a secure location
   - **CSR file** (`.csr`): You'll upload this to AppGallery Connect

**IMPORTANT**: Back up your `.p12` file and remember the password!

## Step 4: Create Debug Certificate in AppGallery Connect

1. In AppGallery Connect, go to your project
2. Navigate to: **Certificates, App IDs and Profiles** → **Certificates**
3. Click **New Certificate**
4. Select:
   - **Certificate type**: `Debug`
   - **Upload CSR file**: Select the `.csr` file from Step 3
5. Click **Submit**
6. **Download** the generated `.cer` file

## Step 5: Register Your Watch Device

1. In AppGallery Connect: **Certificates, App IDs and Profiles** → **Devices**
2. Click **Add Device**
3. Fill in:
   - **Device name**: `WATCH FIT 5` (or your choice)
   - **Device type**: `Smart watch`
   - **UDID**: Paste the UDID from Step 1
4. Click **Submit**

## Step 6: Create App ID

1. In AppGallery Connect: **Certificates, App IDs and Profiles** → **App IDs**
2. Click **New**
3. Fill in:
   - **App type**: `HarmonyOS App`
   - **App name**: `Watch Wandrer`
   - **App package name**: `com.joe.watchwandrer` (must match your `module.json5`)
   - **App category**: `Health & Fitness`
4. Click **Submit**

## Step 7: Create Provisioning Profile

1. In AppGallery Connect: **Certificates, App IDs and Profiles** → **Profiles**
2. Click **Add**
3. Fill in:
   - **App name**: Select `Watch Wandrer` (from Step 6)
   - **Profile type**: `Debug`
   - **Certificate**: Select the certificate from Step 4
   - **Device**: Select your watch from Step 5
4. Click **Submit**
5. **Download** the `.p7b` profile file

## Step 8: Configure Signing in DevEco Studio

1. Open your project in DevEco Studio
2. Go to **File** → **Project Structure** → **Signing Configs**
3. Fill in:
   - **Store File**: Browse to your `.p12` file (from Step 3)
   - **Store Password**: Enter the password you created
   - **Key Alias**: `watch-wandrer-debug`
   - **Key Password**: Same as store password
   - **Certpath File**: Browse to your `.cer` file (from Step 4)
   - **Profile File**: Browse to your `.p7b` file (from Step 7)
4. Click **Apply** → **OK**

## Step 9: Verify Setup

Build and install your app:

```bash
cd /home/joe/projects/watch-wandrer/watch-app

# Clean build
./hvigorw clean

# Build with debug certificate
./hvigorw assembleHap --mode module -p product=default

# Install to watch
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

If successful, you'll see:
```
Install bundle successfully.
```

## Troubleshooting

### "Signature verification failed"
- Check that `.p12`, `.cer`, and `.p7b` files are correctly configured
- Verify the package name in `module.json5` matches the App ID
- Ensure the watch UDID is registered

### "Device not authorized"
- Confirm the watch UDID is registered in AppGallery Connect
- Check that the provisioning profile includes your device

### "Certificate expired"
- Debug certificates are valid for 1 year
- Generate a new certificate and update signing config

## File Locations

After setup, your signing files should be:
```
~/watch-wandrer-certs/
├── watch-wandrer-debug.p12      # Keystore (KEEP SECURE!)
├── watch-wandrer-debug.csr      # Certificate request
├── watch-wandrer-debug.cer      # Debug certificate
└── watch-wandrer-debug.p7b      # Provisioning profile
```

## Next Steps

Once certificates are configured:
1. Use the deployment scripts: `./scripts/deploy-watch.sh`
2. Push tiles: `./scripts/push-tiles.sh`
3. Test on your WATCH FIT 5!

## Important Notes

- **Debug certificates** are for development only
- To publish to AppGallery, you'll need a **release certificate**
- Keep your `.p12` file and password secure
- Certificates expire after 1 year (debug) or 3 years (release)

## References

- [AppGallery Connect](https://developer.huawei.com/consumer/en/service/josp/agc/index.html)
- [HarmonyOS Signing Guide](https://developer.huawei.com/consumer/en/doc/app/agc-help-add-debugcert-0000001914263178)
- [DevEco Studio Documentation](https://developer.huawei.com/consumer/en/deveco-studio/)
