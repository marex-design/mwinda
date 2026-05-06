# Mwinda Project

## Getting Started
Notre objectif est de créer une belle application mobile baptisé ''MWINDA'' qui contrôle une lampe intelligente via Bluetooth (BLE), en utilisant un microcontrôleur ESP32 WROOM32 qui enverra à sa sortie un signal de commande sur le relais pour allumer ou éteindre le fil d'alimentation de la lampe.

# Architecture de l'application Flutter (MWINDA)
Pour garantir un code propre, évolutif et une séparation stricte entre la logique métier et l'interface utilisateur, nous allons adopter une architecture orientée fonctionnalités (Feature-First Architecture). Nous utiliserons Riverpod pour la gestion d'état, car c'est la norme moderne et robuste pour ce type d'application réactive.


```text
lib/
│
├── core/                           # Code partagé et configuration globale
│   ├── constants/                  
│   │   ├── ble_uuids.dart          # UUIDs pour les services/caractéristiques ESP32
│   │   └── app_colors.dart         # Palette de couleurs (mode sombre/clair)
│   ├── theme/
│   │   └── app_theme.dart          # Configuration globale du design
│   └── utils/
│       └── permissions_helper.dart # Permissions Bluetooth et Localisation
│
├── features/                       # Cœur de l'application par fonctionnalités
│   ├── bluetooth_connection/       # Fonctionnalité : Connexion à l'ESP32
│   │   ├── application/
│   │   │   └── ble_provider.dart   # Logique Riverpod (Scan, Connect, Disconnect)
│   │   └── presentation/
│   │       ├── scan_screen.dart    # UI : Liste des appareils détectés
│   │       └── widgets/            # Composants UI (tuiles appareils)
│   │
│   └── lamp_control/               # Fonctionnalité : Contrôle des 4 modes
│       ├── application/
│       │   ├── mode_provider.dart  # Logique Riverpod (états des modes)
│       │   └── command_sender.dart # Conversion UI -> Octets -> BLE
│       └── presentation/
│           ├── control_screen.dart # UI : Tableau de bord principal
│           └── widgets/
│               ├── mode_button.dart# Bouton personnalisé pour les modes
│               └── status_card.dart# Affichage état lampe & microcontrôleur
│
└── main.dart                       # Point d'entrée (ProviderScope, routes)
```
## Explication des couches :
**core/** : Contient tout ce qui est transversal à l'application. Si vous changez l'UUID de l'ESP32 ou une couleur, vous n'aurez qu'à modifier un seul fichier ici.

**application/** (dans les features) : C'est le "cerveau". Aucun code d'interface graphique (pas de Widgets) ne doit s'y trouver. C'est ici que Riverpod écoute les données et gère la logique de commutation exclusive des modes.

**presentation/** (dans les features) : C'est le "visuel". Ces fichiers ne font qu'écouter les variables venant de l'application/ pour dessiner l'écran et envoyer les clics de l'utilisateur vers la logique métier.