import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bluetooth_connection/application/ble_provider.dart';

// État ON/OFF de la lampe
final lampIsOnProvider = StateProvider<bool>((ref) => false);

final commandSenderProvider = Provider((ref) => CommandSender(ref));

class CommandSender {
  final Ref ref;
  CommandSender(this.ref);

  /// Bascule la lampe ON/OFF et envoie la commande BLE
  Future<void> toggleLamp() async {
    final characteristic = ref.read(cachedCharacteristicProvider);
    if (characteristic == null) {
      ref.read(connectionStatusProvider.notifier).state =
          "Non connecté. Appuyez d'abord sur 'Connexion'.";
      return;
    }

    final isOn = ref.read(lampIsOnProvider);
    final command = isOn ? "MANUAL_OFF" : "MANUAL_ON";

    ref.read(connectionStatusProvider.notifier).state = "Envoi : $command...";

    try {
      await characteristic.write(utf8.encode(command), withoutResponse: false);
      // Mettre à jour l'état local APRÈS succès
      ref.read(lampIsOnProvider.notifier).state = !isOn;
      ref.read(connectionStatusProvider.notifier).state =
          isOn ? "Lampe éteinte." : "Lampe allumée.";
    } catch (e) {
      ref.read(connectionStatusProvider.notifier).state =
          "Erreur envoi commande : $e";
    }
  }
}

