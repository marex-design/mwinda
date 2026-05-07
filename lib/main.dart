import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/bluetooth_connection/application/ble_provider.dart';
import 'features/lamp_control/application/command_sender.dart';

void main() {
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const ControlScreenTest(),
    );
  }
}

class ControlScreenTest extends ConsumerWidget {
  const ControlScreenTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);
    final isConnected = ref.watch(connectedDeviceProvider) != null;
    final lampIsOn = ref.watch(lampIsOnProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("MWINDA", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouton de connexion
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.green.shade800 : Colors.amber.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching),
              label: Text(isConnected ? "Connecté" : "Connexion à l'ESP32"),
              onPressed: () => ref.read(bleControllerProvider).scanAndConnect(),
            ),

            const SizedBox(height: 16),

            // Message de statut
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isConnected ? Colors.greenAccent : Colors.amberAccent,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Bouton POWER rond
            GestureDetector(
              onTap: isConnected
                  ? () => ref.read(commandSenderProvider).toggleLamp()
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? (lampIsOn ? Colors.green.shade700 : Colors.red.shade800)
                      : Colors.grey.shade800,
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: lampIsOn
                                ? Colors.green.withOpacity(0.6)
                                : Colors.red.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.power_settings_new,
                  size: 70,
                  color: isConnected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Label ON / OFF
            Text(
              isConnected ? (lampIsOn ? "ALLUMÉE" : "ÉTEINTE") : "— non connecté —",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isConnected
                    ? (lampIsOn ? Colors.green : Colors.red)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

