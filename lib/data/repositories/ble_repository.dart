import 'package:flutter/foundation.dart'; // Pour debugPrint
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BLERepository {
  final String targetServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Erreur lors du scan : $e");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      debugPrint("Connecté à ${device.platformName}");
      
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == targetServiceUuid) {
          debugPrint("Service Smart Lamp trouvé !");
        }
      }
    } catch (e) {
      debugPrint("Erreur de connexion : $e");
    }
  }
}