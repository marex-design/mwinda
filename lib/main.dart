import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/bluetooth_connection/presentation/scan_screen.dart'; // Nous allons créer ce fichier juste après

void main() {
  // ProviderScope est obligatoire pour que Riverpod fonctionne
  runApp(const ProviderScope(child: MwindaApp()));
}

class MwindaApp extends StatelessWidget {
  const MwindaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MWINDA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        brightness: Brightness.dark, // Un style moderne pour une lampe
      ),
      home: const ControlScreenTest(), // Écran temporaire pour tester
    );
  }
}

// Un petit écran rapide pour tester votre bouton immédiatement
class ControlScreenTest extends ConsumerWidget {
  const ControlScreenTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("MWINDA Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => ref.read(bleControllerProvider).scanAndConnect(),
              child: const Text("1. Connexion à l'ESP32"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(commandSenderProvider).sendCommand("MANUAL_ON"),
              child: const Text("2. Allumer (Bip + Relais)"),
            ),
          ],
        ),
      ),
    );
  }
}