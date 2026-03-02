# AndroidDriodFinder - Project Documentation

Cross-platform desktop Android file manager built with Flutter. Connects to Android devices via ADB (USB or Wi-Fi) and provides a dual-pane file browser for managing files between the device and local machine.

## Quick Reference

```
flutter analyze          # Check for errors
flutter run -d macos     # Run on macOS
flutter run -d linux     # Run on Linux
flutter run -d windows   # Run on Windows
dart run build_runner build --delete-conflicting-outputs  # Regenerate freezed files
```

**Dart SDK**: `>=3.3.4 <4.0.0` (supports sealed classes, switch expressions, records)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                     UI (Widgets)                     │
│  Screens → Panels → Dialogs/Tiles/Bars              │
├─────────────────────────────────────────────────────┤
│              Providers (Riverpod)                     │
│  StateNotifier + StateNotifierProvider               │
│  Immutable state classes with copyWith()             │
├─────────────────────────────────────────────────────┤
│                   Services                           │
│  AdbService → FileService / DeviceService            │
│  LocalFileService, TransferService, PreviewService   │
├─────────────────────────────────────────────────────┤
│                Models (Freezed)                      │
│  FileItem, Device, TransferTask                      │
└─────────────────────────────────────────────────────┘
```

**State management**: Riverpod (`flutter_riverpod ^2.5.1`)
**Data classes**: Freezed for immutable models with `copyWith()`
**Theme**: Material 3 with Android green (`#3DDC84`) seed color, light/dark toggle persisted via `shared_preferences`

---

## Project Structure

```
lib/
├── main.dart                          # Entry point, window setup (1280x800, min 1024x768)
├── app.dart                           # MaterialApp with theme + routing
│
├── core/
│   ├── constants.dart                 # AdbConstants (timeouts, ports, limits)
│   ├── exceptions.dart                # AdbNotFoundException, AdbCommandException, etc.
│   └── utils/
│       ├── file_size_formatter.dart   # Bytes → human readable (B/KB/MB/GB)
│       └── platform_utils.dart        # OS detection, home dir, adb executable name
│
├── models/
│   ├── file_item.dart                 # FileItem (name, path, isDirectory, size, modified, permissions, isSymlink)
│   ├── device.dart                    # Device (serial, status, connectionType, model, androidVersion)
│   ├── transfer_task.dart             # TransferTask + TransferDirection/TransferStatus enums
│   ├── sort_option.dart               # SortField enum (name, size, date, type)
│   └── connection_type.dart           # ConnectionType enum (usb, wifi)
│
├── services/
│   ├── adb_service.dart               # Low-level ADB commands (shell, pull, push, pair, install)
│   ├── device_service.dart            # Device scanning, Wi-Fi connect/pair, mDNS discovery
│   ├── file_service.dart              # Device file ops (list, pull, push, delete, rename, copy, mkdir)
│   ├── local_file_service.dart        # Local filesystem ops (list, home dir, roots)
│   ├── transfer_service.dart          # Queue-based transfer manager (max 3 concurrent)
│   └── preview_service.dart           # File preview: classify, cache, read text, open with system app
│
├── providers/
│   ├── adb_provider.dart              # Service singletons (adbService, fileService, etc.)
│   ├── device_provider.dart           # DeviceState/DeviceNotifier - device connections
│   ├── device_file_provider.dart      # DeviceFileState/Notifier - device file browser (family by serial)
│   ├── local_file_provider.dart       # LocalFileState/Notifier - local file browser
│   ├── transfer_provider.dart         # TransferState/Notifier - file transfer queue
│   ├── storage_provider.dart          # StorageInfo via FutureProvider.family
│   ├── theme_provider.dart            # ThemeMode toggle (dark/light) persisted
│   └── preview_provider.dart          # PreviewState/Notifier - file preview with sealed PreviewResult
│
├── screens/
│   ├── home_screen.dart               # Main layout: dual-pane + transfer panel + keyboard shortcuts
│   └── device_selector_screen.dart    # Landing screen when no device connected
│
├── theme/
│   └── app_theme.dart                 # Light/dark ThemeData definitions
│
└── widgets/
    ├── device_panel/
    │   ├── device_status_bar.dart     # Connected device tabs, storage badge, screenshot, theme toggle
    │   ├── quick_access_sidebar.dart  # Collapsible bookmark sidebar (DCIM, Downloads, etc.)
    │   ├── wifi_connect_dialog.dart   # IP:port Wi-Fi connection dialog
    │   └── wifi_pair_dialog.dart      # Wi-Fi pairing dialog with instructions
    │
    ├── file_browser/
    │   ├── file_browser_panel.dart    # Main file browser: breadcrumb + toolbar + list + selection bar
    │   ├── file_breadcrumb_bar.dart   # Clickable path breadcrumbs
    │   ├── file_toolbar.dart          # Navigation, refresh, new folder, sort, search
    │   ├── file_item_tile.dart        # Single file row (icon, name, size, date, permissions)
    │   ├── file_context_menu.dart     # Right-click menu (open, preview, download, upload, delete, etc.)
    │   ├── file_properties_dialog.dart # File info dialog with _PropertyRow pattern
    │   ├── preview_dialog.dart        # File preview dialog (image zoom/pan, text viewer, file info)
    │   └── selection_action_bar.dart  # Bottom bar when files selected (download, upload, delete)
    │
    └── transfer/
        └── transfer_panel.dart        # Expandable transfer queue with progress bars
```

---

## Key Patterns

### Provider Pattern (Riverpod)

All services are singleton `Provider`s defined in `adb_provider.dart`:

```dart
// Service providers (singleton, lazy)
final adbServiceProvider = Provider<AdbService>((ref) => AdbService());
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService(ref.read(adbServiceProvider));
});
```

State is managed with `StateNotifier` + `StateNotifierProvider`:

```dart
final deviceFileProvider =
    StateNotifierProvider.family<DeviceFileNotifier, DeviceFileState, String>(
        (ref, serial) {
  return DeviceFileNotifier(ref.read(fileServiceProvider), serial);
});
```

- Use `.family` when state is keyed by a parameter (e.g., device serial)
- Use `.autoDispose` when state should be cleaned up (e.g., preview)

### State Class Pattern

All state classes follow this pattern:

```dart
class SomeState {
  final Type field;
  const SomeState({this.field = defaultValue});

  SomeState copyWith({Type? field, bool clearError = false}) {
    return SomeState(field: field ?? this.field);
  }

  // Computed getters for derived state
  List<Item> get filteredItems => ...;
}
```

### Model Pattern (Freezed)

Models use `@freezed` annotation:

```dart
@freezed
class FileItem with _$FileItem {
  const factory FileItem({
    required String name,
    required String absolutePath,
    @Default(false) bool isSymlink,
  }) = _FileItem;
}
```

After changing a model, regenerate: `dart run build_runner build --delete-conflicting-outputs`

### Context Menu Pattern

Context menus use `WidgetsBinding.instance.addPostFrameCallback` to show dialogs after the menu closes:

```dart
PopupMenuItem(
  child: const _MenuTile(Icons.info_outline, 'Properties'),
  onTap: () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(context: context, builder: ...);
    });
  },
),
```

### File Browser Panel (Dual-Pane)

`FileBrowserPanel` is used twice in `HomeScreen` - once with `isDevicePanel: true` (left) and once with `isDevicePanel: false` (right). It branches on `isDevicePanel` to choose the right provider:

```dart
// Reading state
final devState = isDevicePanel ? ref.watch(deviceFileProvider(serial!)) : null;
final locState = !isDevicePanel ? ref.watch(localFileProvider) : null;

// Navigating
if (isDevicePanel && serial != null) {
  ref.read(deviceFileProvider(serial).notifier).navigateTo(path);
} else if (!isDevicePanel) {
  ref.read(localFileProvider.notifier).navigateTo(path);
}
```

---

## Services Detail

### AdbService (`services/adb_service.dart`)

Low-level ADB wrapper. Finds ADB binary via `ANDROID_HOME` or `which`/`where`.

| Method | Description |
|--------|-------------|
| `getAdbPath()` | Finds and caches ADB binary path |
| `runAdb(args)` | Run `adb <args>`, throws on non-zero exit |
| `runAdbForDevice(serial, args)` | Run `adb -s <serial> <args>` |
| `shell(serial, commandArgs)` | Run `adb -s <serial> shell <args>` (doesn't throw on non-zero by default) |
| `pairDevice(ip, port, code)` | Pair via `adb pair`, sends code via stdin |
| `installApk(serial, path)` | `adb install -r` |
| `getStorageInfo(serial)` | Parses `df /data` output → `(total, used, free)` record |
| `captureScreenshot(serial)` | `adb exec-out screencap -p` → `Uint8List` |
| `ensureServerRunning()` | `adb start-server` |

### FileService (`services/file_service.dart`)

Device file operations via ADB. Depends on `AdbService`.

| Method | Description |
|--------|-------------|
| `listDirectory(serial, path)` | `ls -la` → parsed `List<FileItem>` (dirs first) |
| `pullFile/pullFileWithProgress` | `adb pull` with optional progress polling (500ms) |
| `pushFile/pushFileWithProgress` | `adb push` with optional progress via `stat` polling |
| `delete(serial, path)` | `rm -rf` |
| `rename(serial, old, new)` | `mv` |
| `copy(serial, src, dest)` | `cp -r` |
| `createDirectory(serial, path)` | `mkdir -p` |
| `getFileSize(serial, path)` | `stat -c %s` |

### PreviewService (`services/preview_service.dart`)

File preview support. Classifies files by extension and manages a cache.

| Method | Description |
|--------|-------------|
| `classifyFile(fileName)` | Returns `FileCategory` enum (image/video/audio/text/pdf/apk/unsupported) |
| `pullToCache(serial, path, modified)` | Pulls to temp dir, keyed by `serial_pathHash_modifiedMs.ext`. Skips if cached. |
| `readTextContent(localPath)` | Reads file as string |
| `openWithSystem(localPath)` | `open` (macOS) / `xdg-open` (Linux) / `cmd /c start` (Windows) |

**Size limits**: Images >50MB and text >5MB open externally instead of inline.

**Text extensions**: txt, log, md, json, xml, yaml, yml, csv, dart, js, ts, py, java, kt, c, cpp, h, html, css, scss, sh, bash, zsh, bat, ps1, rb, go, rs, swift, gradle, properties, cfg, ini, toml, env, gitignore, dockerfile

**Cache path**: `<tempDir>/android_finder_preview/<serial>_<pathHash>_<modifiedMs>.<ext>`

### TransferService (`services/transfer_service.dart`)

Queue-based file transfer with max 3 concurrent operations.

- Emits `TransferTask` updates via `Stream<TransferTask>`
- Tasks flow: `queued` → `inProgress` → `completed`/`failed`
- Gets source file size before starting for progress calculation

### LocalFileService (`services/local_file_service.dart`)

Local filesystem via `dart:io`. Lists directories, gets home dir, gets filesystem roots.

### DeviceService (`services/device_service.dart`)

Device management: scanning (`adb devices -l`), Wi-Fi connect/pair, mDNS discovery (`adb mdns services`), auto-connect, enriching device info (model, Android version via `getprop`).

---

## Providers Detail

### `device_provider.dart` — DeviceState

Manages discovered and connected devices:
- `discoveredDevices` — from scanning
- `connectedDevices` — Map<serial, Device> of active connections
- `activeSerial` — currently viewed device
- Methods: `scan()`, `selectDevice()`, `connectWifi()`, `autoConnectWifi()`, `pairDevice()`, `disconnectDevice()`

### `device_file_provider.dart` — DeviceFileState (family by serial)

Device file browser state:
- `currentPath`, `files`, `isLoading`, `errorMessage`
- `pathHistory` + `historyIndex` — back/forward navigation
- `selectedFiles` — Set<String> of selected absolute paths
- `searchQuery`, `sortField`, `sortAscending`
- Computed: `filteredAndSortedFiles`, `canGoBack`, `canGoForward`, `selectedTotalBytes`
- Methods: `navigateTo()`, `refresh()`, `goBack()`, `goForward()`, `goUp()`, `deleteSelected()`, `renameFile()`, `createDirectory()`

### `local_file_provider.dart` — LocalFileState

Mirrors DeviceFileState for local filesystem. Same structure, no serial parameter.

### `transfer_provider.dart` — TransferState

Wraps TransferService, listens to task update stream:
- `tasks` — List<TransferTask>
- Computed: `completedCount`, `failedCount`, `queuedCount`, `hasActiveTasks`
- Methods: `enqueueDownload()`, `enqueueUpload()`, `cancelTransfer()`, `clearCompleted()`

### `preview_provider.dart` — PreviewState

File preview with sealed result types:

```dart
sealed class PreviewResult {}
class ImagePreviewResult extends PreviewResult { Uint8List bytes; }
class TextPreviewResult extends PreviewResult { String content; String fileName; }
class ExternalOpenResult extends PreviewResult {}
class FileInfoResult extends PreviewResult { FileItem file; }
```

State: `isLoading`, `progress` (0.0-1.0), `statusText`, `result`, `error`

`previewFile()` flow:
1. Classify file by extension
2. APK/unsupported → `FileInfoResult`
3. Device files → pull to cache with progress
4. Local files → read directly
5. Image (<=50MB) → `ImagePreviewResult` with bytes
6. Text (<=5MB) → `TextPreviewResult` with content
7. Video/audio/PDF or oversized → `ExternalOpenResult` (opens with system app)

---

## UI Layout

```
┌──────────────────────────────────────────────────────────┐
│ DeviceStatusBar (device tabs, storage, screenshot, theme)│
├──────────┬───┬───────────────────────────────────────────┤
│ Sidebar  │   │                                           │
│ (Quick   │ D │  FileBrowserPanel (isDevicePanel: false)   │
│  Access) │ i │  ┌─ FileBreadcrumbBar ──────────────────┐ │
│ ─────── │ v │  ├─ FileToolbar (nav, sort, search) ────┤ │
│ DCIM     │ i │  ├─ ListView of FileItemTile ───────────┤ │
│ Download │ d │  │   - file icon, name, size, date      │ │
│ Music    │ e │  │   - single tap = select              │ │
│ Pictures │ r │  │   - double tap = open dir / preview  │ │
│ Movies   │   │  │   - right click = context menu       │ │
│ Documents│   │  │   - drag & drop for transfers        │ │
│          │   │  └─ SelectionActionBar (if selected) ───┘ │
│          │   │                                           │
│  FileBrowserPanel (isDevicePanel: true)                   │
│  (same structure as right panel)                         │
├──────────┴───┴───────────────────────────────────────────┤
│ TransferPanel (expandable, shows active/queued/done)     │
└──────────────────────────────────────────────────────────┘
```

### Keyboard Shortcuts (HomeScreen)

| Key | Action |
|-----|--------|
| F5 | Refresh both panels |
| Ctrl+A | Select all (device panel) |
| Ctrl+F | Focus search in both panels |
| Delete | Delete selected (device, with confirmation) |
| Escape | Clear selection + search |
| Enter | Open selected folder |

### File Interactions

| Action | Behavior |
|--------|----------|
| Single tap | Toggle file selection |
| Double tap directory | Navigate into directory |
| Double tap file | Open preview dialog |
| Right click | Context menu |
| Drag files | Cross-panel transfer (upload/download) |
| Drop external files | Upload to device (on device panel) |

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `freezed_annotation` + `freezed` | Immutable data classes |
| `path_provider` | Temp directory for preview cache |
| `path` | Path manipulation |
| `desktop_drop` | Drag & drop file support |
| `file_picker` | Save/directory dialogs |
| `intl` | Date formatting |
| `window_manager` | Window size/position |
| `shared_preferences` | Theme persistence |
| `uuid` | Transfer task IDs |
| `collection` | Collection utilities |

---

## Common Tasks

### Adding a new file operation

1. Add method to `FileService` (uses `AdbService.shell()` or `runAdbForDevice()`)
2. Add action method to `DeviceFileNotifier` (calls service, then `refresh()`)
3. Add UI trigger in `file_context_menu.dart` or `file_browser_panel.dart`

### Adding a new provider

1. Create `lib/providers/your_provider.dart`
2. Define state class with `copyWith()` and computed getters
3. Define `StateNotifier` subclass
4. Export provider: `final yourProvider = StateNotifierProvider<YourNotifier, YourState>(...)`
5. If it depends on a service, inject via `ref.read(serviceProvider)` in factory

### Adding a new dialog/widget

1. Create in appropriate `lib/widgets/` subdirectory
2. Use `ConsumerWidget`/`ConsumerStatefulWidget` if it needs Riverpod
3. For context menu triggers, wrap in `WidgetsBinding.instance.addPostFrameCallback`
4. Follow `_PropertyRow` pattern for info displays
5. Follow `_MenuTile` pattern for context menu items

### Modifying a Freezed model

1. Edit the `@freezed` class in `lib/models/`
2. Run: `dart run build_runner build --delete-conflicting-outputs`
3. The `.freezed.dart` file will be regenerated

---

## Constants (`core/constants.dart`)

```dart
defaultAdbPort        = '5555'
commandTimeout        = 30 seconds
longCommandTimeout    = 10 minutes
defaultDevicePath     = '/sdcard'
maxConcurrentTransfers = 3
progressPollInterval   = 500ms
```

## Custom Exceptions (`core/exceptions.dart`)

| Exception | When |
|-----------|------|
| `AdbNotFoundException` | ADB binary not found on system |
| `AdbCommandException` | ADB command returns non-zero exit code |
| `DeviceUnreachableException` | Device serial unreachable |
| `TransferFailedException` | File transfer fails |

---

## File Preview Feature

**Trigger**: Double-tap non-directory file, or right-click → "Preview"

**Flow**:
1. `PreviewDialog` opens → calls `previewNotifierProvider.notifier.previewFile()`
2. File classified by extension → routed to appropriate handler
3. Device files pulled to cache first (with progress bar)
4. Result displayed: image (zoom/pan), text (monospace), or file info
5. Video/audio/PDF open with system app → dialog auto-closes

**Preview dialog features**:
- `InteractiveViewer` for images (zoom/pan up to 10x)
- `SelectableText` monospace for text/code files
- Determinate progress bar during file pull
- Auto-close on external app open (`ExternalOpenResult`)
