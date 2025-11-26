import 'package:flutter/material.dart';
import 'screens/auth/driver_login.dart';
import 'screens/auth/driver_signup.dart';
import 'screens/auth/user_login.dart';
import 'screens/auth/user_signup.dart';
import 'screens/driver_dashboard.dart';
import 'screens/role_selection.dart';
import 'screens/splash.dart';
import 'screens/user_dashboard.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TakeKarApp());
}

class TakeKarApp extends StatelessWidget {
  const TakeKarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Takeكار',
      theme: buildAppTheme(),
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (_) => const SplashScreen(),
        RoleSelectionScreen.route: (_) => const RoleSelectionScreen(),
        UserLoginScreen.route: (_) => const UserLoginScreen(),
        UserSignupScreen.route: (_) => const UserSignupScreen(),
        UserDashboardScreen.route: (_) => const UserDashboardScreen(),
        DriverLoginScreen.route: (_) => const DriverLoginScreen(),
        DriverSignupScreen.route: (_) => const DriverSignupScreen(),
        DriverDashboardScreen.route: (_) => const DriverDashboardScreen(),
      },
    );
  }
}
