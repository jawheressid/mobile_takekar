# TakeCar 🚍📍
Application mobile Flutter pour **chercher un trajet**, **suivre une ligne en temps réel**, consulter **l’historique** et **signaler un problème**.  
Le projet utilise **Firebase** comme backend (Auth + Cloud Firestore + Realtime Database).

---

## 📌 Objectif du projet
TakeCar aide l’utilisateur à :
- trouver le meilleur itinéraire entre deux lieux (avec ou sans GPS),
- suivre la position d’un bus en direct,
- revoir ses trajets passés,
- envoyer un signalement (retard, paiement, autre).

---

## ✨ Fonctionnalités principales

### 1) Authentification & rôles
- Connexion / inscription via **Firebase Authentication**
- Profil utilisateur stocké sur **Cloud Firestore**
- Gestion des rôles (`user` / `driver`) + validations (ex: code chauffeur)

> Service clé : `AuthService`

### 2) Recherche de trajets
- Recherche par texte (nom / ville / préfixe) dans Firestore
- Recherche par GPS : arrêt le plus proche (calcul de distance via `latlong2`)
- Génération de trajets :
  - **directs** (1 ligne)
  - **avec correspondance** (2 lignes + arrêt commun)

> Service clé : `TripSearchService`

### 3) Suivre une ligne (Temps réel)
- L’utilisateur choisit **ligne** + **région**
- Récupération des lignes/régions depuis Firestore
- Position bus en direct depuis **Realtime Database**
- Fallback : si pas de live data, afficher un arrêt par défaut

> Service clé : `FollowLineService`

### 4) Historique
- Liste des trajets passés (UI)
- Stats rapides : nombre de trajets + temps total

> Page : `HistoryPage`

### 5) Signaler un problème
- Choix type + description
- SnackBar de confirmation (backend à connecter plus tard)

> Page : `ReportProblemPage`

---

## 🧱 Stack technique
- **Flutter / Dart**
- **Firebase Authentication**
- **Cloud Firestore**
- **Firebase Realtime Database (RTDB)**
- Packages :
  - `cloud_firestore`
  - `firebase_auth`
  - `firebase_database`
  - `geolocator`
  - `latlong2`

---

## 🏗️ Architecture (important)
On n’a pas un serveur classique. Le “backend” est Firebase, et la logique métier est organisée en **services** côté Flutter :

- UI (pages/screens) ➜ appelle une fonction simple
- Service ➜ contient :
  - requêtes Firebase
  - validations / règles métier
  - parsing / conversions (models)
  - gestion des erreurs

Exemples :
- `auth.signInWithEmailPassword(...)`
- `tripSearch.searchTrips(...)`
- `followLine.watchBusLocation(...)`

---
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

