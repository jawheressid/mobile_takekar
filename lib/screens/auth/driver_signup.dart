import 'package:flutter/material.dart';
import '../../widgets/gradient_shell.dart';
import '../../widgets/inputs.dart';
import '../../widgets/buttons.dart';
import '../../theme/app_colors.dart';
import '../driver_dashboard.dart';
import 'driver_login.dart';

class DriverSignupScreen extends StatelessWidget {
  const DriverSignupScreen({super.key});
  static const String route = '/driver-signup';

  @override
  Widget build(BuildContext context) {
    return GradientShell(
      title: 'Inscription',
      subtitle: 'Espace Chauffeur',
      onBack: () => Navigator.of(context).pop(),
      children: [
        const RoundedTextField(label: 'Nom complet', hint: 'Votre nom'),
        const SizedBox(height: 14),
        const RoundedTextField(
          label: 'Adresse email',
          hint: 'votre@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        const RoundedTextField(label: 'Mot de passe', hint: '••••••••', obscureText: true),
        const SizedBox(height: 14),
        const RoundedTextField(label: 'Code chauffeur', hint: 'Code à 6 chiffres'),
        const SizedBox(height: 14),
        const RoundedTextField(label: 'Numéro de bus', hint: 'BUS-2025-001'),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Créer le compte',
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(DriverDashboardScreen.route, (route) => false),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Déjà inscrit ? ', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(DriverLoginScreen.route),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ],
    );
  }
}
