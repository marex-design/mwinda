// Extrait simplifié pour le test manuel
ElevatedButton(
  onPressed: () => ref.read(commandSenderProvider).sendCommand("MANUAL_ON"),
  child: const Text("Allumer la lampe"),
),
ElevatedButton(
  onPressed: () => ref.read(commandSenderProvider).sendCommand("MANUAL_OFF"),
  child: const Text("Éteindre la lampe"),
)