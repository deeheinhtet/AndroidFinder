import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';

class ClipboardState {
  final List<FileItem> items;
  final bool isFromDevice;
  final String? sourceSerial;
  final String sourceDir;

  const ClipboardState({
    this.items = const [],
    this.isFromDevice = false,
    this.sourceSerial,
    this.sourceDir = '',
  });

  bool get hasItems => items.isNotEmpty;

  ClipboardState copyWith({
    List<FileItem>? items,
    bool? isFromDevice,
    String? sourceSerial,
    String? sourceDir,
  }) {
    return ClipboardState(
      items: items ?? this.items,
      isFromDevice: isFromDevice ?? this.isFromDevice,
      sourceSerial: sourceSerial ?? this.sourceSerial,
      sourceDir: sourceDir ?? this.sourceDir,
    );
  }
}

class ClipboardNotifier extends StateNotifier<ClipboardState> {
  ClipboardNotifier() : super(const ClipboardState());

  void copy(
      List<FileItem> items, bool isFromDevice, String? serial, String dir) {
    state = ClipboardState(
      items: items,
      isFromDevice: isFromDevice,
      sourceSerial: serial,
      sourceDir: dir,
    );
  }

  void clear() {
    state = const ClipboardState();
  }
}

final clipboardProvider =
    StateNotifierProvider<ClipboardNotifier, ClipboardState>((ref) {
  return ClipboardNotifier();
});
