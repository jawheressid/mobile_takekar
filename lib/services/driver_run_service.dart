import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class DriverRunService {
  DriverRunService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
    DriverLocationService? locationService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance,
        _locationService = locationService ?? DriverLocationService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;
  final DriverLocationService _locationService;

  Future<DriverRun> startService({
    required String busId,
    required String lineName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const DriverRunException(DriverRunError.notSignedIn);
    }

    final line = await _fetchLineByName(lineName);
    final runRef = _firestore.collection('serviceRuns').doc();
    final busRef = _firestore.collection('buses').doc(busId);
    final driverRef = _firestore.collection('drivers').doc(user.uid);

    
    await _firestore.runTransaction((tx) async {
      final busSnap = await tx.get(busRef);
      if (!busSnap.exists) {
        throw const DriverRunException(DriverRunError.busNotFound);
      }

      final driverSnap = await tx.get(driverRef);
      if (!driverSnap.exists) {
        throw const DriverRunException(DriverRunError.driverNotFound);
      }

      final driverData = driverSnap.data() ?? <String, dynamic>{};
      final allowedBusIds = driverData['allowedBusIds'];
      if (allowedBusIds is List) {
        
        if (allowedBusIds.isEmpty) {
          throw const DriverRunException(DriverRunError.busNotAllowed);
        }
        final isAllowed = allowedBusIds.any((value) {
          if (value is String) return value == busId;
          if (value is num) return value.toString() == busId;
          return false;
        });
        if (!isAllowed) {
          throw const DriverRunException(DriverRunError.busNotAllowed);
        }
      } else {
        throw const DriverRunException(DriverRunError.busNotAllowed);
      }

      
      final activeRunId = driverData['activeRunId'];
      if (activeRunId is String && activeRunId.isNotEmpty) {
        throw const DriverRunException(DriverRunError.driverAlreadyRunning);
      }

      
      final busData = busSnap.data() ?? <String, dynamic>{};
      final currentRunId = busData['currentRunId'];
      if (currentRunId is String && currentRunId.isNotEmpty) {
        throw const DriverRunException(DriverRunError.busAlreadyRunning);
      }

      tx.set(runRef, {
        'status': 'running',
        'busId': busId,
        'lineId': line.id,
        'lineName': line.name,
        'driverId': user.uid,
        'startedAt': FieldValue.serverTimestamp(),
        'stoppedAt': null,
        'lastLocationAt': FieldValue.serverTimestamp(),
      });

      tx.update(busRef, {
        'status': 'in_service',
        'currentRunId': runRef.id,
      });

      tx.update(driverRef, {
        'activeRunId': runRef.id,
      });
    });

    return DriverRun(
      id: runRef.id,
      busId: busId,
      lineId: line.id,
      lineName: line.name,
      driverId: user.uid,
    );
  }

  Future<void> stopService(
    DriverRun run, {
    bool clearLiveRun = true,
  }) async {
    final runRef = _firestore.collection('serviceRuns').doc(run.id);
    final busRef = _firestore.collection('buses').doc(run.busId);
    final driverRef = _firestore.collection('drivers').doc(run.driverId);

    await _firestore.runTransaction((tx) async {
      tx.update(runRef, {
        'status': 'stopped',
        'stoppedAt': FieldValue.serverTimestamp(),
      });
      tx.update(busRef, {
        'status': 'available',
        'currentRunId': null,
      });
      tx.update(driverRef, {
        'activeRunId': null,
      });
    });

    if (clearLiveRun) {
      await _database.ref('liveRuns/${run.id}').remove();
    }
  }

  Future<void> pushLocation(DriverRun run) async {
    final position = await _locationService.getCurrentPosition();
    final speedKmh = position.speed.isNaN ? null : position.speed * 3.6;
    final heading = position.heading.isNaN ? null : position.heading;

    
    final payload = {
      'busId': run.busId,
      'lineId': run.lineId,
      'driverId': run.driverId,
      'lat': position.latitude,
      'lng': position.longitude,
      if (speedKmh != null) 'speed': speedKmh,
      if (heading != null) 'heading': heading,
      'updatedAt': ServerValue.timestamp,
    };

    await Future.wait([
      _database.ref('liveRuns/${run.id}').set(payload),
      _firestore.collection('serviceRuns').doc(run.id).update({
        'lastLocationAt': FieldValue.serverTimestamp(),
      }),
    ]);
  }

  Future<void> ensureLocationReady() => _locationService.ensurePermissions();

  Future<_LineInfo> _fetchLineByName(String lineName) async {
    final snapshot = await _firestore
        .collection('lines')
        .where('name', isEqualTo: lineName)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw const DriverRunException(DriverRunError.lineNotFound);
    }

    final doc = snapshot.docs.first;
    final data = doc.data();
    final active = data['active'];
    if (active is bool && !active) {
      throw const DriverRunException(DriverRunError.lineInactive);
    }

    final resolvedName = (data['name'] as String?)?.trim();
    return _LineInfo(
      id: doc.id,
      name: resolvedName == null || resolvedName.isEmpty
          ? lineName
          : resolvedName,
    );
  }
}

class DriverRunTracker {
  DriverRunTracker({
    required DriverRunService service,
    required DriverRun run,
    this.interval = const Duration(seconds: 15),
  })  : _service = service,
        _run = run;

  final DriverRunService _service;
  final DriverRun _run;
  final Duration interval;

  Timer? _timer;
  bool _sending = false;

  Future<void> start() async {
    await _service.ensureLocationReady();
    await _service.pushLocation(_run);

    
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_sending) return;
    _sending = true;
    _service.pushLocation(_run).catchError((_) {}).whenComplete(() {
      _sending = false;
    });
  }
}

class DriverLocationService {
  Future<void> ensurePermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const DriverLocationException(DriverLocationError.disabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const DriverLocationException(DriverLocationError.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DriverLocationException(DriverLocationError.deniedForever);
    }
  }

  Future<Position> getCurrentPosition() async {
    await ensurePermissions();
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

class DriverRun {
  const DriverRun({
    required this.id,
    required this.busId,
    required this.lineId,
    required this.lineName,
    required this.driverId,
  });

  final String id;
  final String busId;
  final String lineId;
  final String lineName;
  final String driverId;
}

class DriverRunException implements Exception {
  const DriverRunException(this.error);
  final DriverRunError error;
}

enum DriverRunError {
  notSignedIn,
  lineNotFound,
  lineInactive,
  busNotFound,
  busNotAllowed,
  busAlreadyRunning,
  driverNotFound,
  driverAlreadyRunning,
}

class DriverLocationException implements Exception {
  const DriverLocationException(this.error);
  final DriverLocationError error;
}

enum DriverLocationError { disabled, denied, deniedForever }

String friendlyDriverRunErrorMessage(Object error) {
  if (error is DriverRunException) {
    switch (error.error) {
      case DriverRunError.notSignedIn:
        return 'Veuillez vous connecter.';
      case DriverRunError.lineNotFound:
        return 'Ligne n’existe pas.';
      case DriverRunError.lineInactive:
        return 'Ligne inactive.';
      case DriverRunError.busNotFound:
        return 'Bus n’existe pas.';
      case DriverRunError.busNotAllowed:
        return 'Chauffeur n’a pas accès à ce bus.';
      case DriverRunError.busAlreadyRunning:
        return 'Bus déjà en service.';
      case DriverRunError.driverNotFound:
        return 'Profil chauffeur introuvable.';
      case DriverRunError.driverAlreadyRunning:
        return 'Chauffeur déjà en service.';
    }
  }

  if (error is DriverLocationException) {
    switch (error.error) {
      case DriverLocationError.disabled:
        return 'Localisation désactivée.';
      case DriverLocationError.denied:
        return 'Localisation refusée.';
      case DriverLocationError.deniedForever:
        return 'Autorisez la localisation dans les réglages.';
    }
  }

  return 'Une erreur est survenue. Veuillez réessayer.';
}

class _LineInfo {
  const _LineInfo({required this.id, required this.name});
  final String id;
  final String name;
}
