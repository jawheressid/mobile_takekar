import 'package:flutter/material.dart';
import '../../widgets/gradient_shell.dart';
import '../../widgets/inputs.dart';
import '../../widgets/buttons.dart';
import '../user_dashboard.dart';
import 'user_login.dart';

class UserSignupScreen extends StatelessWidget {
  const UserSignupScreen({super.key});
  static const String route = '/user-signup';

  @override
  Widget build(BuildContext context) {
    return GradientShell(
      title: 'Inscription',
      subtitle: 'Créer un compte Utilisateur',
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
        const RoundedTextField(label: 'Confirmer le mot de passe', hint: '••••••••', obscureText: true),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Créer le compte',
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(UserDashboardScreen.route, (route) => false),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Déjà inscrit ? '),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(UserLoginScreen.route),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ],
    );
  }
}
