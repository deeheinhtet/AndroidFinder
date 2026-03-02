import '../models/connection_type.dart';
import '../models/device.dart';
import 'adb_service.dart';

class DeviceService {
  final AdbService _adb;

  DeviceService(this._adb);

  Future<List<Device>> scanDevices() async {
    await _adb.ensureServerRunning();
    final output = await _adb.runAdb(['devices', '-l']);
    final lines = output.trim().split('\n');

    final devices = <Device>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;

      final serial = parts[0];
      final status = parts[1];

      String? model;
      for (final part in parts) {
        if (part.startsWith('model:')) {
          model = part.substring(6).replaceAll('_', ' ');
          break;
        }
      }

      final connectionType =
          serial.contains(':') ? ConnectionType.wifi : ConnectionType.usb;

      devices.add(Device(
        serialNumber: serial,
        status: status,
        connectionType: connectionType,
        model: model,
        isConnected: status == 'device',
      ));
    }

    return devices;
  }

  /// Pairs with a wireless debugging device. Must be done once before connecting.
  Future<String> pairDevice(String ip, int port, String pairingCode) async {
    final result = await _adb.pairDevice(ip, port, pairingCode);
    return result;
  }

  Future<Device> connectWifi(String ip, int port) async {
    final target = '$ip:$port';
    await _adb.runAdb(['connect', target]);

    final devices = await scanDevices();
    final device = devices.where((d) => d.serialNumber == target).firstOrNull;
    if (device == null || device.status != 'device') {
      throw Exception('Failed to connect to $target');
    }
    return device;
  }

  /// Discovers Wi-Fi devices on the local network using mDNS.
  /// Returns devices that have wireless debugging enabled and are already paired.
  Future<List<({String name, String ip, int port})>> discoverWifiDevices() async {
    await _adb.ensureServerRunning();
    try {
      final output = await _adb.runAdb(['mdns', 'services']);
      final lines = output.trim().split('\n');
      final results = <({String name, String ip, int port})>[];

      for (final line in lines) {
        if (line.startsWith('List of') || line.trim().isEmpty) continue;
        // Format: adb-R5CT41B1GXL-E8IzsO	_adb-tls-connect._tcp	192.168.1.36:45515
        final parts = line.split('\t');
        if (parts.length < 3) continue;

        final name = parts[0].trim();
        final addressPart = parts[2].trim();

        // Only include connectable services (_adb-tls-connect)
        if (!parts[1].contains('_adb-tls-connect')) continue;

        final colonIdx = addressPart.lastIndexOf(':');
        if (colonIdx < 0) continue;
        final ip = addressPart.substring(0, colonIdx);
        final port = int.tryParse(addressPart.substring(colonIdx + 1));
        if (port == null) continue;

        results.add((name: name, ip: ip, port: port));
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Auto-discovers and connects to the first available Wi-Fi device.
  Future<Device> autoConnectWifi() async {
    final discovered = await discoverWifiDevices();
    if (discovered.isEmpty) {
      throw Exception(
          'No Wi-Fi devices found. Make sure Wireless Debugging is enabled and the device is paired.');
    }

    // Try to connect to each discovered device
    for (final d in discovered) {
      try {
        return await connectWifi(d.ip, d.port);
      } catch (_) {
        continue;
      }
    }

    throw Exception('Could not connect to any discovered device.');
  }

  Future<void> disconnectWifi(String serial) async {
    await _adb.runAdb(['disconnect', serial]);
  }

  Future<Device> enrichDeviceInfo(Device device) async {
    if (device.status != 'device') return device;

    try {
      final model =
          (await _adb.shell(device.serialNumber, ['getprop', 'ro.product.model']))
              .trim();
      final version = (await _adb.shell(
              device.serialNumber, ['getprop', 'ro.build.version.release']))
          .trim();
      return device.copyWith(
        model: model.isNotEmpty ? model : device.model,
        androidVersion: version.isNotEmpty ? version : null,
      );
    } catch (_) {
      return device;
    }
  }
}
