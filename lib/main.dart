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
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.amber : Colors.grey),
          trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.amber.withOpacity(0.5) : Colors.grey.shade800),
        ),
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
    final activeMode = ref.watch(activeModeProvider);
    final lampIsOn = ref.watch(lampIsOnProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("MWINDA", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- En-tête de connexion ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.green.shade800 : Colors.amber.shade800,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching, color: Colors.white),
              label: Text(isConnected ? "Connecté à l'ESP32" : "Connexion à l'ESP32", style: const TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () => ref.read(bleControllerProvider).scanAndConnect(),
            ),
            const SizedBox(height: 8),
            Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isConnected ? Colors.greenAccent : Colors.amberAccent)),
            const SizedBox(height: 30),

            // --- Liste des Fonctionnalités ---
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  
                  // 1. MODE MANUEL
                  _buildFeatureTile(
                    title: "Mode Manuel",
                    icon: Icons.touch_app,
                    isActive: activeMode == AppMode.manual,
                    isDisabled: activeMode != AppMode.none && activeMode != AppMode.manual,
                    isConnected: isConnected,
                    onToggle: (val) => ref.read(commandSenderProvider).setMode(val ? AppMode.manual : AppMode.none),
                  ),
                  
                  // Animation de déroulement pour le bouton Power
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutBack, // Animation fluide avec un léger rebond
                    child: activeMode == AppMode.manual
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: _buildPowerButton(ref, isConnected, lampIsOn),
                          )
                        : const SizedBox.shrink(), // Vide si inactif
                  ),

                  const SizedBox(height: 12),

                  // 2. MODE DÉTECTION DE MOUVEMENT (PIR)
                  _buildFeatureTile(
                    title: "Détection de mouvement",
                    icon: Icons.directions_run,
                    isActive: activeMode == AppMode.motion,
                    isDisabled: activeMode != AppMode.none && activeMode != AppMode.motion,
                    isConnected: isConnected,
                    onToggle: (val) => ref.read(commandSenderProvider).setMode(val ? AppMode.motion : AppMode.none),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget personnalisé pour une ligne de fonctionnalité
  Widget _buildFeatureTile({
    required String title,
    required IconData icon,
    required bool isActive,
    required bool isDisabled,
    required bool isConnected,
    required Function(bool) onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isActive ? Colors.amber : Colors.transparent, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: isActive ? Colors.amber : (isDisabled ? Colors.grey.shade700 : Colors.white)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.amber : (isDisabled ? Colors.grey.shade700 : Colors.white),
          ),
        ),
        trailing: Switch(
          value: isActive,
          onChanged: (!isConnected || isDisabled) ? null : onToggle,
        ),
      ),
    );
  }

  // Le gros bouton Power (extrait pour garder le code propre)
  Widget _buildPowerButton(WidgetRef ref, bool isConnected, bool lampIsOn) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => ref.read(commandSenderProvider).toggleLamp(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lampIsOn ? Colors.amber.shade600 : Colors.grey.shade800,
              boxShadow: lampIsOn 
                  ? [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 30, spreadRadius: 5)] 
                  : [],
            ),
            child: Icon(Icons.power_settings_new, size: 60, color: lampIsOn ? Colors.white : Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 16),
        Text(lampIsOn ? "LAMPE ALLUMÉE" : "LAMPE ÉTEINTE", style: TextStyle(fontWeight: FontWeight.bold, color: lampIsOn ? Colors.amber : Colors.grey)),
      ],
    );
  }
}
