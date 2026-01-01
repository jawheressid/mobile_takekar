import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_role.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> driverDoc(String uid) =>
      _firestore.collection('drivers').doc(uid);

  Future<void> upsertUserProfile({
    required String uid,
    required UserRole role,
    String? fullName,
    String? driverCode,
    String? busNumber,
  }) {
    final base = <String, dynamic>{
      'role': userRoleToString(role),
      if (fullName != null) 'fullName': fullName,
      if (driverCode != null) 'driverCode': driverCode,
      if (busNumber != null) 'busNumber': busNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final ref = userDoc(uid);
    return _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        tx.set(ref, <String, dynamic>{
          ...base,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, base, SetOptions(merge: true));
      }
    });
  }

  Future<void> upsertDriverProfile({
    required String uid,
    required String name,
    required List<int> allowedBusIds,
  }) {
    final data = <String, dynamic>{
      'name': name,
      'allowedBusIds': allowedBusIds,
      'activeRunId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final ref = driverDoc(uid);
    return _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        tx.set(ref, <String, dynamic>{
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, data, SetOptions(merge: true));
      }
    });
  }

  Future<UserRole?> fetchUserRole(String uid) async {
    final snapshot = await userDoc(uid).get();
    final data = snapshot.data();
    return userRoleFromString(data?['role'] as String?);
  }

  Future<bool> verifyDriverCode({
    required String uid,
    required String code,
  }) async {
    final snapshot = await userDoc(uid).get();
    final data = snapshot.data();
    final stored = (data?['driverCode'] as String?)?.trim();
    if (stored == null || stored.isEmpty) return true;
    return stored == code.trim();
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();
}

class MissingUserRoleException implements Exception {
  MissingUserRoleException(this.uid);
  final String uid;
}

class InvalidUserRoleException implements Exception {
  InvalidUserRoleException({required this.expected, required this.actual});
  final UserRole expected;
  final UserRole actual;
}

class InvalidDriverCodeException implements Exception {}

Future<UserRole> requireUserRole(AuthService auth, String uid) async {
  final role = await auth.fetchUserRole(uid);
  if (role == null) throw MissingUserRoleException(uid);
  return role;
}

String friendlyAuthErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  switch (error.code) {
    case 'invalid-email':
      return 'Adresse email invalide.';
    case 'user-disabled':
      return 'Ce compte est désactivé.';
    case 'user-not-found':
      return 'Aucun compte trouvé avec cet email.';
    case 'wrong-password':
      return 'Mot de passe incorrect.';
    case 'email-already-in-use':
      return 'Cet email est déjà utilisé.';
    case 'weak-password':
      return 'Mot de passe trop faible (6 caractères minimum).';
    case 'operation-not-allowed':
      return 'Cette méthode de connexion n’est pas activée.';
    case 'network-request-failed':
      return 'Problème réseau. Vérifiez votre connexion.';
    default:
      return error.message ?? 'Une erreur est survenue. Veuillez réessayer.';
  }
}

String friendlyRoleErrorMessage(Object error) {
  if (error is MissingUserRoleException) {
    return 'Profil incomplet. Veuillez vous réinscrire.';
  }
  if (error is InvalidUserRoleException) {
    return 'Ce compte ne correspond pas à ce type de connexion.';
  }
  if (error is InvalidDriverCodeException) {
    return 'Code chauffeur incorrect.';
  }
  return 'Une erreur est survenue. Veuillez réessayer.';
}
