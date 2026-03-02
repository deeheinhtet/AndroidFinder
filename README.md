# AndroidFinder

A cross-platform desktop Android file manager built with Flutter. Connect to Android devices via ADB (USB or Wi-Fi) and manage files using a dual-pane file browser.

## Features

- **Dual-pane file browser** — Device files on the left, local files on the right
- **USB & Wi-Fi connections** — Connect via USB, Wi-Fi pairing, or auto-discovery (mDNS)
- **File transfers** — Drag & drop or use context menus to upload/download files with a queued transfer manager (up to 3 concurrent)
- **File preview** — Preview images (zoom/pan), text/code files, and open media with system apps
- **Device management** — Multi-device tabs, storage info, screenshots
- **Quick access sidebar** — Bookmarks for common directories (DCIM, Downloads, Music, etc.)
- **Keyboard shortcuts** — F5 refresh, Ctrl+A select all, Delete, search with Ctrl+F
- **Setup guide** — Built-in ADB installation instructions and phone setup tips for new users
- **Dark/Light theme** — Material 3 theming with persistent toggle

## Prerequisites

- **Flutter SDK** (Dart SDK >=3.3.4)
- **ADB** (Android Debug Bridge) — the app includes a setup guide to help with installation:
  - macOS: `brew install android-platform-tools`
  - Linux: `sudo apt install android-tools-adb`
  - Windows: Download [SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools) and add to PATH
  - Or install Android Studio (includes ADB)

## Getting Started

```bash
# Clone the repository
git clone https://github.com/user/AndroidDriodFinder.git
cd AndroidDriodFinder

# Install dependencies
flutter pub get

# Generate Freezed files
dart run build_runner build --delete-conflicting-outputs

# Run on your desktop platform
flutter run -d macos    # macOS
flutter run -d linux    # Linux
flutter run -d windows  # Windows
```

## Phone Setup

1. Go to **Settings > About Phone**
2. Tap **Build Number** 7 times to enable Developer Options
3. Go to **Settings > Developer Options**
4. Enable **USB Debugging**
5. (Optional) Enable **Wireless Debugging** for Wi-Fi connections
6. When connecting via USB, tap **Allow** on the phone prompt

## Project Structure

```
lib/
├── main.dart              # Entry point, window setup
├── app.dart               # MaterialApp with theme + routing
├── core/                  # Constants, exceptions, utilities
├── models/                # Freezed data classes (FileItem, Device, TransferTask, etc.)
├── services/              # ADB, file, device, transfer, preview services
├── providers/             # Riverpod state management
├── screens/               # Home screen, device selector
├── theme/                 # Light/dark theme definitions
└── widgets/               # UI components (device panel, file browser, transfer panel)
```

## Architecture

- **State management**: Riverpod with StateNotifier
- **Data classes**: Freezed for immutable models
- **Theme**: Material 3 with Android green (#3DDC84) seed color

## Development

```bash
# Check for errors
flutter analyze

# Regenerate Freezed files after model changes
dart run build_runner build --delete-conflicting-outputs
```

## License

This project is open source.
