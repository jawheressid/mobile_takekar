import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/cards.dart';
import 'auth/user_login.dart';
import 'auth/driver_login.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});
  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFF2D9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33FFC107),
                          blurRadius: 18,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.directions_bus, color: AppColors.sunrise, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'TAKE ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: 'كار', style: TextStyle(color: AppColors.sunriseDeep)),
                      ],
                    ),
                    style: const TextStyle(fontSize: 28, letterSpacing: 0.5, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(width: 46, height: 4, decoration: BoxDecoration(color: AppColors.sunrise, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(height: 12),
                  const Text(
                    'Choisissez votre profil',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 26),
                  ProfileCard(
                    icon: Icons.person_outline,
                    title: 'Utilisateur',
                    subtitle: 'Rechercher un transport',
                    onTap: () => Navigator.of(context).pushNamed(UserLoginScreen.route),
                  ),
                  const SizedBox(height: 16),
                  ProfileCard(
                    icon: Icons.engineering_outlined,
                    title: 'Chauffeur',
                    subtitle: 'Conduire un bus',
                    onTap: () => Navigator.of(context).pushNamed(DriverLoginScreen.route),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
