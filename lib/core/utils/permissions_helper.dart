import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestBlePermissions() async {
  if (!Platform.isAndroid) return true;

  final statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();

  return statuses.values.every((status) => status.isGranted);
}

/// Vérifie si les services de localisation sont activés sur le téléphone.
/// Sur Android, c'est obligatoire pour le scan BLE.
Future<bool> isLocationServiceEnabled() async {
  if (!Platform.isAndroid) return true;
  return await Permission.locationWhenInUse.serviceStatus.isEnabled;
}
