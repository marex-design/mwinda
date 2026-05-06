import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/ble_uuids.dart';
import '../../bluetooth_connection/application/ble_provider.dart';

final commandSenderProvider = Provider((ref) => CommandSender(ref));

class CommandSender {
  final Ref ref;
  CommandSender(this.ref);

  Future<void> sendCommand(String command) async {
    final device = ref.read(connectedDeviceProvider);
    if (device == null) return;

    // Découvrir les services si ce n'est pas déjà fait
    List<BluetoothService> services = await device.discoverServices();
    
    for (var service in services) {
      if (service.uuid.toString() == BleUuids.serviceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == BleUuids.characteristicUuid) {
            // Envoyer la commande sous forme d'octets (UTF-8)
            await characteristic.write(utf8.encode(command));
            print("Commande envoyée : $command");
          }
        }
      }
    }
  }
}