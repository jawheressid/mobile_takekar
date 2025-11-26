
# TAKEكار – Application mobile Flutter

Application Flutter de suivi et de recherche de transports (espace Utilisateur et Chauffeur) avec une interface moderne : sélection de profil, écrans de connexion / inscription et tableaux de bord dédiés.

## Prérequis

- Flutter SDK installé (3.x recommandé)
- Dart inclus avec Flutter
- Un IDE adapté (Android Studio, VS Code, IntelliJ, etc.)
- Pour les plateformes cibles :
  - Android : Android Studio + émulateur ou appareil physique avec mode développeur
  - iOS : Xcode + simulateur ou appareil physique (sur macOS)
  - Web (optionnel) : navigateur récent (Chrome, Edge…)

Vérifiez votre installation :

```bash
flutter doctor
```

## Installation du projet

Dans un terminal, placez‑vous dans le dossier du projet :

```bash
cd mon_app
```

Installez les dépendances :

```bash
flutter pub get
```

## Lancer l’application

### Android

1. Branchez un appareil Android (ou démarrez un émulateur dans Android Studio).
2. Depuis le dossier `mon_app` :

```bash
flutter run -d android
```

### iOS (sur macOS)

1. Ouvrez un simulateur iOS ou connectez un iPhone.
2. Depuis `mon_app` :

```bash
flutter run -d ios
```

> Si Xcode n’est pas encore configuré, lancez `flutter doctor` pour voir les éléments manquants.

### Web (optionnel)

Activez la cible web si besoin :

```bash
flutter config --enable-web
flutter devices   # pour vérifier que Chrome/Web apparaît
```

Puis :

```bash
flutter run -d chrome
```

## Structure principale du code

- `lib/main.dart` – Point d’entrée de l’application et définition des routes (splash, sélection de rôle, écrans d’authentification et tableaux de bord).
- `lib/theme/app_colors.dart` – Palette de couleurs.
- `lib/theme/app_theme.dart` – Thème global (typographie, couleurs, etc.).
- `lib/widgets/` – Widgets réutilisables (boutons, champs de saisie, cartes, shell avec dégradé…).
- `lib/screens/` – Écrans :
  - `splash.dart` – Écran de bienvenue « takeكار vous souhaite une bonne journée ».
  - `role_selection.dart` – Choix du profil (Utilisateur / Chauffeur).
  - `auth/` – Connexion / inscription pour chaque type d’utilisateur.
  - `user_dashboard.dart` – Tableau de bord utilisateur.
  - `driver_dashboard.dart` – Tableau de bord chauffeur.

## Personnalisation

- Couleurs : ajuster les constantes dans `lib/theme/app_colors.dart`.
- Textes / labels : modifier les chaînes dans les fichiers d’écrans sous `lib/screens/`.
- Navigation : ajouter ou modifier des routes dans `lib/main.dart`.

## Tests

Pour lancer les tests Flutter (s’il y en a dans `test/`) :

```bash
flutter test
```

---

Une fois l’interface stabilisée, vous pourrez connecter un backend (par exemple Firebase Auth + Firestore) en remplaçant la navigation « factice » des boutons de connexion/inscription par de vrais appels réseau.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
