# Mwinda Project

## Getting Started
Notre objectif est de créer une belle application mobile baptisé ''MWINDA'' qui contrôle une lampe intelligente via Bluetooth (BLE), en utilisant un microcontrôleur ESP32 WROOM32 qui enverra à sa sortie un signal de commande sur le relais pour allumer ou éteindre le fil d'alimentation de la lampe.

# Architecture de l'application Flutter (MWINDA)
Pour garantir un code propre, évolutif et une séparation stricte entre la logique métier et l'interface utilisateur, nous allons adopter une architecture orientée fonctionnalités (Feature-First Architecture). Nous utiliserons Riverpod pour la gestion d'état, car c'est la norme moderne et robuste pour ce type d'application réactive.

lib/
│
├── core/                           # Code partagé et configuration globale
│   ├── constants/                  
│   │   ├── ble_uuids.dart          # Stockage des UUIDs pour les services et caractéristiques de l'ESP32
│   │   └── app_colors.dart         # Palette de couleurs pour MWINDA (ex: mode sombre/clair)
│   ├── theme/
│   │   └── app_theme.dart          # Configuration globale du design (boutons, textes, etc.)
│   └── utils/
│       └── permissions_helper.dart # Logique pour demander les permissions Bluetooth et Localisation (crucial sur Android/iOS)
│
├── features/                       # Le cœur de l'application divisé par fonctionnalités
│   │
│   ├── bluetooth_connection/       # Fonctionnalité : Scanner et se connecter à l'ESP32
│   │   ├── application/
│   │   │   └── ble_provider.dart   # Logique Riverpod pour gérer l'état de la connexion (Scan, Connecté, Déconnecté)
│   │   └── presentation/
│   │       ├── scan_screen.dart    # Interface UI : Liste des appareils détectés
│   │       └── widgets/            # Composants UI réutilisables (ex: tuile d'un appareil Bluetooth)
│   │
│   └── lamp_control/               # Fonctionnalité : Contrôle des 4 modes de la lampe
│       ├── application/
│       │   ├── mode_provider.dart  # Logique Riverpod gérant l'état exclusif des modes (Manuel, LDR, PIR, Sonore)
│       │   └── command_sender.dart # Service chargé de convertir les actions UI en octets et de les envoyer via BLE
│       └── presentation/
│           ├── control_screen.dart # Interface UI : Le tableau de bord principal avec les 4 modes
│           └── widgets/
│               ├── mode_button.dart# Composant UI : Bouton personnalisé pour activer un mode
│               └── status_card.dart# Composant UI : Affichage de l'état actuel de la lampe et du microcontrôleur
│
└── main.dart                       # Point d'entrée de l'application, initialisation de Riverpod (ProviderScope) et des routes

## Explication des couches :
core/ : Contient tout ce qui est transversal à l'application. Si vous changez l'UUID de l'ESP32 ou une couleur, vous n'aurez qu'à modifier un seul fichier ici.

application/ (dans les features) : C'est le "cerveau". Aucun code d'interface graphique (pas de Widgets) ne doit s'y trouver. C'est ici que Riverpod écoute les données et gère la logique de commutation exclusive des modes.

presentation/ (dans les features) : C'est le "visuel". Ces fichiers ne font qu'écouter les variables venant de l'application/ pour dessiner l'écran et envoyer les clics de l'utilisateur vers la logique métier.