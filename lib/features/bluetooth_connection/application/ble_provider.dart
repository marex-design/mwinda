import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/ble_uuids.dart';
import '../../../core/utils/permissions_helper.dart';

// Appareil connecté
final connectedDeviceProvider = StateProvider<BluetoothDevice?>((ref) => null);

// Statut visible par l'UI
final connectionStatusProvider = StateProvider<String>((ref) => "En attente...");

// Caractéristique BLE mise en cache après connexion (évite discoverServices() répétés)
final cachedCharacteristicProvider = StateProvider<BluetoothCharacteristic?>((ref) => null);

// Contrôleur BLE
final bleControllerProvider = Provider((ref) => BleController(ref));

class BleController {
  final Ref ref;
  BleController(this.ref);

  void _setStatus(String msg) =>
      ref.read(connectionStatusProvider.notifier).state = msg;

  Future<void> scanAndConnect() async {
    _setStatus("Vérification des permissions...");

    final hasPermissions = await requestBlePermissions();
    if (!hasPermissions) {
      _setStatus("Permissions refusées. Autorisez le Bluetooth dans les paramètres.");
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      _setStatus("Veuillez activer le Bluetooth.");
      return;
    }

    // Vérifier que les services de localisation sont activés (obligatoire Android)
    final locationEnabled = await isLocationServiceEnabled();
    if (!locationEnabled) {
      _setStatus("Activez la Localisation (GPS) dans les paramètres du téléphone, puis réessayez.");
      return;
    }

    // Stopper un éventuel scan déjà en cours
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    _setStatus("Scan en cours... (8 sec)");

    bool found = false;
    StreamSubscription? subscription;

    try {
      // Écouter AVANT de démarrer le scan
      subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (!found &&
              (r.device.advName == "MWINDA_ESP32" ||
                  r.device.platformName == "MWINDA_ESP32")) {
            found = true;
            _setStatus("MWINDA_ESP32 trouvé ! Connexion...");
            FlutterBluePlus.stopScan();
            subscription?.cancel();
            _connectToDevice(r.device);
            break;
          }
        }
      });

      // androidUsesFineLocation: false car le manifest déclare neverForLocation
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        androidUsesFineLocation: false,
      );

      // Attendre la fin réelle du scan
      await FlutterBluePlus.isScanning.where((s) => s == false).first;

      if (!found) {
        subscription.cancel();
        _setStatus("MWINDA_ESP32 introuvable. Vérifiez que l'ESP32 est allumé.");
      }
    } catch (e) {
      subscription?.cancel();
      _setStatus("Erreur scan : $e");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      ref.read(connectedDeviceProvider.notifier).state = device;
      _setStatus("Connexion réussie ! Découverte des services...");

      // Découvrir les services UNE SEULE FOIS et mettre en cache la caractéristique
      final services = await device.discoverServices();
      BluetoothCharacteristic? found;
      for (var service in services) {
        if (service.uuid.toString() == BleUuids.serviceUuid) {
          for (var c in service.characteristics) {
            if (c.uuid.toString() == BleUuids.characteristicUuid) {
              found = c;
              break;
            }
          }
        }
        if (found != null) break;
      }

      if (found != null) {
        ref.read(cachedCharacteristicProvider.notifier).state = found;
        _setStatus("✅ Connecté à MWINDA_ESP32 !");
      } else {
        _setStatus("Connecté mais caractéristique BLE introuvable. Vérifiez l'ESP32.");
      }
    } catch (e) {
      _setStatus("Erreur de connexion : $e");
    }
  }

  Future<void> disconnectDevice() async {
    final device = ref.read(connectedDeviceProvider);
    if (device != null) {
      await device.disconnect();
      ref.read(connectedDeviceProvider.notifier).state = null;
      ref.read(cachedCharacteristicProvider.notifier).state = null;
      _setStatus("Déconnecté.");
    }
  }
}

