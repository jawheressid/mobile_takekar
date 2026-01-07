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

## 📁 Structure (exemple)
