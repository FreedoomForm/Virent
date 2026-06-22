# Virent — iOS & Android App

> Expo React Native. Single codebase for iOS and Android.

## Two ways to build the APK

### Option A: Native Gradle build via GitHub Actions (recommended)

No Expo account needed. Uses standard Gradle + Android SDK.

```bash
# Trigger via tag push (creates GitHub Release with APK attached)
git tag v1.1.0
git push origin v1.1.0

# Or trigger manually:
# GitHub → Actions → "Build Android APK (Native Gradle, no Expo)" → Run workflow
```

The workflow (`.github/workflows/build-apk-native.yml`) does:
1. `npm install --legacy-peer-deps`
2. `npx expo prebuild --platform android --no-install` — generates native `android/` folder
3. `cd android && ./gradlew assembleDebug` — builds APK
4. Uploads APK as GitHub Actions artifact (90 day retention)
5. On tag pushes, also attaches APK to the GitHub Release

After the build finishes, the APK is available at:
```
https://github.com/FreedoomForm/Virent/releases/download/v1.1.0/virent-android.apk
```

This is the URL that the "Download APK" button in the Windows desktop app uses.

### Option B: Local build via EAS

Requires an Expo account and `EXPO_TOKEN` secret.

```bash
cd mobile
npm install --legacy-peer-deps
eas build --platform android --profile preview
```

## EAS Build fix (ERESOLVE error)

If you see this error during `eas build`:

```
npm ERR! ERESOLVE could not resolve dependency:
npm ERR! peer react@"18.0.0" from react-native@0.69.6
npm ERR! Found: react@18.2.0
```

**This is fixed by the `.npmrc` file in this directory** with `legacy-peer-deps=true`.

## Local development

```bash
cd mobile
npm install --legacy-peer-deps
cp .env.example .env
# Edit .env with your REST API URL
npx expo start --tunnel
# Scan QR with Expo Go on your phone
```

## Project structure

```text
mobile/
├── App.tsx              # Entry — bottom-tab navigation (Map | Trips | Wallet | Settings)
├── app.json             # Expo config
├── eas.json             # EAS Build profiles (development / preview / production)
├── babel.config.js      # Babel config (reanimated + dotenv)
├── tsconfig.json        # TypeScript config
├── .npmrc               # legacy-peer-deps=true (fixes ERESOLVE)
├── .env.example         # API URL template
├── styles/tokens.ts     # Design tokens (BarqScoot light theme)
├── types/env.d.ts       # TypeScript declarations for @env
└── assets/              # Splash, icons (add your own)
```

## Tech stack

```text
Framework    React Native 0.69.6 via Expo SDK 46
Language     TypeScript 4.9
Navigation   @react-navigation (bottom-tabs + native-stack)
Icons        @expo/vector-icons (Ionicons)
Maps         react-native-maps 0.31
QR scanner   expo-barcode-scanner
Storage      @react-native-async-storage/async-storage
Build / CI   GitHub Actions (native Gradle) or EAS Build
```

## Comparison: Virent vs BarqScoot

We also build BarqScoot's APK for comparison via `.github/workflows/build-barqscoot-apk.yml`:

| Property | Virent | BarqScoot |
|----------|--------|-----------|
| Framework | React Native 0.69 (Expo SDK 46) | Flutter 3.27 |
| Language | TypeScript | Dart |
| State | React hooks | Riverpod |
| Navigation | @react-navigation | go_router |
| Maps | react-native-maps (Google Maps) | flutter_map (Leaflet) |
| Icons | Ionicons | Material Icons |
| APK size | ~24 MB | ~20 MB |
| Build time (CI) | ~6 min | ~8 min |

The BarqScoot APK can be downloaded from the Windows desktop app's Dashboard → "APK Comparison" card.
