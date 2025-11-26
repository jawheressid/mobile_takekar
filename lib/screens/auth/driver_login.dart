import 'package:flutter/material.dart';
import '../../widgets/gradient_shell.dart';
import '../../widgets/inputs.dart';
import '../../widgets/buttons.dart';
import '../../theme/app_colors.dart';
import '../driver_dashboard.dart';
import 'driver_signup.dart';

class DriverLoginScreen extends StatelessWidget {
  const DriverLoginScreen({super.key});
  static const String route = '/driver-login';

  @override
  Widget build(BuildContext context) {
    return GradientShell(
      title: 'Connexion',
      subtitle: 'Espace Chauffeur',
      onBack: () => Navigator.of(context).pop(),
      children: [
        const RoundedTextField(
          label: 'Adresse email',
          hint: 'votre@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        const RoundedTextField(label: 'Mot de passe', hint: '••••••••', obscureText: true),
        const SizedBox(height: 14),
        const RoundedTextField(label: 'Code chauffeur', hint: 'Code à 6 chiffres'),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Se connecter',
          onPressed: () => Navigator.of(context).pushNamed(DriverDashboardScreen.route),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pas encore de compte ? ', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(DriverSignupScreen.route),
              style: TextButton.styleFrom(foregroundColor: AppColors.sunriseDeep),
              child: const Text('S’inscrire'),
            ),
          ],
        ),
      ],
    );
  }
}
