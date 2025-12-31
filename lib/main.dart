import 'pages/report_problem_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'pages/trip_details_page.dart';
import 'pages/trip_results_page.dart';
import 'pages/trip_search_page.dart';
import 'screens/auth/driver_login.dart';
import 'screens/auth/driver_signup.dart';
import 'screens/auth/user_login.dart';
import 'screens/auth/user_signup.dart';
import 'screens/driver_dashboard.dart';
import 'screens/follow_line/follow_line_select.dart';
import 'screens/role_selection.dart';
import 'screens/splash.dart';
import 'screens/user_dashboard.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseInitError;
  try {
    // NOTE: On Web, Firebase needs explicit config (via --dart-define) otherwise FirebaseAuth/Firestore will crash.
    await Firebase.initializeApp(
      options: kIsWeb ? _webFirebaseOptions() : null,
    );
  } catch (e) {
    firebaseInitError = e;
  }

  runApp(TakeKarApp(firebaseInitError: firebaseInitError));
}

class TakeKarApp extends StatelessWidget {
  const TakeKarApp({super.key, this.firebaseInitError});

  final Object? firebaseInitError;

  @override
  Widget build(BuildContext context) {
    if (firebaseInitError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Takeكار',
        theme: buildAppTheme(),
        home: _FirebaseInitErrorScreen(error: firebaseInitError!),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Takeكار',
      theme: buildAppTheme(),
      initialRoute: SplashScreen.route,
      routes: {
        ReportProblemPage.route: (_) => const ReportProblemPage(),
        TripSearchPage.route: (_) => const TripSearchPage(),
        TripResultsPage.route: (_) => const TripResultsPage(),
        TripDetailsPage.route: (_) => const TripDetailsPage(),
        SplashScreen.route: (_) => const SplashScreen(),
        RoleSelectionScreen.route: (_) => const RoleSelectionScreen(),
        UserLoginScreen.route: (_) => const UserLoginScreen(),
        UserSignupScreen.route: (_) => const UserSignupScreen(),
        UserDashboardScreen.route: (_) => const UserDashboardScreen(),
        FollowLineSelectScreen.route: (_) => const FollowLineSelectScreen(),
        DriverLoginScreen.route: (_) => const DriverLoginScreen(),
        DriverSignupScreen.route: (_) => const DriverSignupScreen(),
        DriverDashboardScreen.route: (_) => const DriverDashboardScreen(),
      },
    );
  }
}

FirebaseOptions _webFirebaseOptions() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
  const databaseURL = String.fromEnvironment('FIREBASE_DATABASE_URL');

  if (apiKey.isEmpty ||
      appId.isEmpty ||
      messagingSenderId.isEmpty ||
      projectId.isEmpty) {
    throw StateError(
      'Missing Firebase Web config. Define: FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID.',
    );
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain.isEmpty ? null : authDomain,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    measurementId: measurementId.isEmpty ? null : measurementId,
    databaseURL: databaseURL.isEmpty ? null : databaseURL,
  );
}

class _FirebaseInitErrorScreen extends StatelessWidget {
  const _FirebaseInitErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Firebase non initialisé (Web)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ajoutez la config Firebase Web (dart-define) puis relancez.',
              ),
              const SizedBox(height: 12),
              const SelectableText(
                'flutter run -d chrome \\\n'
                '  --dart-define=FIREBASE_API_KEY=... \\\n'
                '  --dart-define=FIREBASE_APP_ID=... \\\n'
                '  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \\\n'
                '  --dart-define=FIREBASE_PROJECT_ID=...',
              ),
              const SizedBox(height: 12),
              Text(error.toString(), style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
