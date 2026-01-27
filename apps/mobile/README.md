# Site360 Mobile App

React Native mobile application for iOS and Android, optimized for on-site data collection.

## Features

- Mobile-first design for field use
- Offline capabilities
- Camera integration for photo documentation
- Real-time sync with Supabase
- Daily check logging
- Material tracking

## Tech Stack

- **Framework**: React Native
- **State Management**: Zustand / React Query
- **Database**: Supabase
- **Platforms**: iOS, Android

## Development

```bash
# Install dependencies
pnpm install

# iOS
pnpm ios              # Run on iOS simulator
pnpm ios:device       # Run on connected device

# Android
pnpm android          # Run on Android emulator
pnpm android:device   # Run on connected device
```

## Directory Structure

```
mobile/
├── android/         # Android native code
├── ios/            # iOS native code
└── src/            # React Native source code
```
