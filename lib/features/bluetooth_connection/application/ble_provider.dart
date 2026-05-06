import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Un provider pour exposer l'appareil connecté s'il y en a un
final connectedDeviceProvider = StateProvider<BluetoothDevice?>((ref) => null);

// Un provider pour gérer les actions BLE (Scan, Connect, Disconnect)
final bleControllerProvider = Provider((ref) => BleController(ref));

class BleController {
  final Ref ref;
  BleController(this.ref);

  Future<void> scanAndConnect() async {
    // S'assurer que le Bluetooth est activé (les permissions doivent être gérées via Utils)
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      print("Veuillez activer le Bluetooth");
      return;
    }

    print("Début du scan...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    // Écouter les résultats du scan
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.advName == "MWINDA_ESP32" || r.device.platformName == "MWINDA_ESP32") {
          print("MWINDA_ESP32 trouvé ! Tentative de connexion...");
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          break;
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print("Connecté à MWINDA_ESP32 !");
      
      // Mettre à jour l'état de l'application
      ref.read(connectedDeviceProvider.notifier).state = device;
      
      // La découverte des services (et l'envoi des commandes) se fera dans l'étape 3
    } catch (e) {
      print("Erreur de connexion : $e");
    }
  }

  Future<void> disconnectDevice() async {
    final device = ref.read(connectedDeviceProvider);
    if (device != null) {
      await device.disconnect();
      ref.read(connectedDeviceProvider.notifier).state = null;
    }
  }
}