import 'package:flutter/material.dart';
import '../../widgets/gradient_shell.dart';
import '../../widgets/inputs.dart';
import '../../widgets/buttons.dart';
import '../../theme/app_colors.dart';
import '../user_dashboard.dart';
import 'user_signup.dart';

class UserLoginScreen extends StatelessWidget {
  const UserLoginScreen({super.key});
  static const String route = '/user-login';

  @override
  Widget build(BuildContext context) {
    return GradientShell(
      title: 'Connexion',
      subtitle: 'Bienvenue sur TAKE كار',
      onBack: () => Navigator.of(context).pop(),
      children: [
        const RoundedTextField(
          label: 'Adresse email',
          hint: 'votre@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        const RoundedTextField(
          label: 'Mot de passe',
          hint: '••••••••',
          obscureText: true,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: AppColors.sunriseDeep),
            child: const Text('Mot de passe oublié ?'),
          ),
        ),
        const SizedBox(height: 6),
        PrimaryButton(
          label: 'Se connecter',
          onPressed: () => Navigator.of(context).pushNamed(UserDashboardScreen.route),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pas encore de compte ? ', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(UserSignupScreen.route),
              style: TextButton.styleFrom(foregroundColor: AppColors.sunriseDeep),
              child: const Text('S’inscrire'),
            ),
          ],
        ),
      ],
    );
  }
}
