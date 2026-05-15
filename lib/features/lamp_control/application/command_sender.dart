import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bluetooth_connection/application/ble_provider.dart';

// Enumération pour définir clairement les modes possibles
enum AppMode { none, manual, motion }

// État du mode actif
final activeModeProvider = StateProvider<AppMode>((ref) => AppMode.none);

// État ON/OFF de la lampe (uniquement pour le mode manuel)
final lampIsOnProvider = StateProvider<bool>((ref) => false);

final commandSenderProvider = Provider((ref) => CommandSender(ref));

class CommandSender {
  final Ref ref;
  CommandSender(this.ref);







 // Fonction générique pour envoyer une commande BLE
  Future<void> _sendBleCommand(String command) async {
    final characteristic = ref.read(cachedCharacteristicProvider);
    if (characteristic == null) return;
    try {
      await characteristic.write(utf8.encode(command), withoutResponse: false);
    } catch (e) {
      ref.read(connectionStatusProvider.notifier).state = "Erreur BLE : $e";
    }
  }

  // Changer de mode
  Future<void> setMode(AppMode newMode) async {
    ref.read(activeModeProvider.notifier).state = newMode;
    ref.read(lampIsOnProvider.notifier).state = false; // Réinitialise l'état manuel
    
    if (newMode == AppMode.manual) {
      await _sendBleCommand("MODE_MANUAL");
    } else if (newMode == AppMode.motion) {
      await _sendBleCommand("MODE_MOTION");
    } else {
      await _sendBleCommand("MODE_NONE");
    }
  }
 
 

  // Action du bouton manuel
  Future<void> toggleLamp() async {
    if (ref.read(activeModeProvider) != AppMode.manual) return; // Sécurité

    final isOn = ref.read(lampIsOnProvider);
    final command = isOn ? "MANUAL_OFF" : "MANUAL_ON";
    
    await _sendBleCommand(command);
    ref.read(lampIsOnProvider.notifier).state = !isOn;
  }
}


