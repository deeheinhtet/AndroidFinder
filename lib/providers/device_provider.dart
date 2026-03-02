import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_type.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import 'adb_provider.dart';

class DeviceState {
  final List<Device> discoveredDevices;
  final Map<String, Device> connectedDevices;
  final String? activeSerial;
  final bool isScanning;
  final bool isConnecting;
  final String? errorMessage;

  const DeviceState({
    this.discoveredDevices = const [],
    this.connectedDevices = const {},
    this.activeSerial,
    this.isScanning = false,
    this.isConnecting = false,
    this.errorMessage,
  });

  Device? get activeDevice => connectedDevices[activeSerial];
  bool get hasConnectedDevices => connectedDevices.isNotEmpty;

  DeviceState copyWith({
    List<Device>? discoveredDevices,
    Map<String, Device>? connectedDevices,
    String? activeSerial,
    bool? isScanning,
    bool? isConnecting,
    String? errorMessage,
    bool clearActiveSerial = false,
    bool clearError = false,
  }) {
    return DeviceState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      activeSerial:
          clearActiveSerial ? null : (activeSerial ?? this.activeSerial),
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DeviceNotifier extends StateNotifier<DeviceState> {
  final DeviceService _deviceService;

  DeviceNotifier(this._deviceService) : super(const DeviceState());

  Future<void> scan() async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final devices = await _deviceService.scanDevices();
      state = state.copyWith(
        discoveredDevices: devices,
        isScanning: false,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> selectDevice(Device device) async {
    final serial = device.serialNumber;
    // If already connected, just switch to it
    if (state.connectedDevices.containsKey(serial)) {
      state = state.copyWith(activeSerial: serial);
      return;
    }

    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final enriched = await _deviceService.enrichDeviceInfo(device);
      final connected = enriched.copyWith(isConnected: true);
      final updated = Map<String, Device>.from(state.connectedDevices)
        ..[serial] = connected;
      state = state.copyWith(
        connectedDevices: updated,
        activeSerial: serial,
        isConnecting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String> pairDevice(String ip, int port, String pairingCode) async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final result = await _deviceService.pairDevice(ip, port, pairingCode);
      state = state.copyWith(isConnecting: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> connectWifi(String ip, int port) async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final device = await _deviceService.connectWifi(ip, port);
      final enriched = await _deviceService.enrichDeviceInfo(device);
      final connected = enriched.copyWith(isConnected: true);
      final serial = connected.serialNumber;
      final updated = Map<String, Device>.from(state.connectedDevices)
        ..[serial] = connected;
      state = state.copyWith(
        connectedDevices: updated,
        activeSerial: serial,
        isConnecting: false,
        discoveredDevices: [...state.discoveredDevices, enriched],
      );
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> autoConnectWifi() async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final device = await _deviceService.autoConnectWifi();
      final enriched = await _deviceService.enrichDeviceInfo(device);
      final connected = enriched.copyWith(isConnected: true);
      final serial = connected.serialNumber;
      final updated = Map<String, Device>.from(state.connectedDevices)
        ..[serial] = connected;
      state = state.copyWith(
        connectedDevices: updated,
        activeSerial: serial,
        isConnecting: false,
        discoveredDevices: [...state.discoveredDevices, enriched],
      );
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setActiveDevice(String serial) {
    if (state.connectedDevices.containsKey(serial)) {
      state = state.copyWith(activeSerial: serial);
    }
  }

  Future<void> disconnectDevice(String serial) async {
    final device = state.connectedDevices[serial];
    if (device == null) return;

    try {
      if (device.connectionType == ConnectionType.wifi) {
        await _deviceService.disconnectWifi(serial);
      }
    } catch (_) {}

    final updated = Map<String, Device>.from(state.connectedDevices)
      ..remove(serial);

    String? nextActive;
    if (updated.isNotEmpty) {
      if (state.activeSerial == serial) {
        nextActive = updated.keys.first;
      } else {
        nextActive = state.activeSerial;
      }
    }

    state = state.copyWith(
      connectedDevices: updated,
      activeSerial: nextActive,
      clearActiveSerial: nextActive == null,
    );
  }

  Future<void> disconnect() async {
    final serial = state.activeSerial;
    if (serial == null) return;
    await disconnectDevice(serial);
  }
}

final deviceProvider =
    StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  return DeviceNotifier(ref.read(deviceServiceProvider));
});
