import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/gradient_shell.dart';
import '../../widgets/inputs.dart';
import '../../widgets/buttons.dart';
import '../../theme/app_colors.dart';
import '../user_dashboard.dart';
import 'user_signup.dart';
import '../../services/auth_service.dart';
import '../../models/user_role.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});
  static const String route = '/user-login';

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizedEmail() => _emailController.text.trim().toLowerCase();

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final credential = await _auth.signInWithEmailPassword(
        email: _normalizedEmail(),
        password: _passwordController.text,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception('Missing uid');
      }

      final role = await requireUserRole(_auth, uid);
      if (role != UserRole.user) {
        await _auth.signOut();
        throw InvalidUserRoleException(expected: UserRole.user, actual: role);
      }

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(UserDashboardScreen.route, (route) => false);
    } catch (e) {
      if (!mounted) return;
      final message = (e is FirebaseAuthException)
          ? friendlyAuthErrorMessage(e)
          : friendlyRoleErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _normalizedEmail();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez d’abord un email valide.')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de réinitialisation envoyé.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = friendlyAuthErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientShell(
      title: 'Connexion',
      subtitle: 'Bienvenue sur TAKE كار',
      onBack: _isSubmitting ? null : () => Navigator.of(context).pop(),
      children: [
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                RoundedTextField(
                  label: 'Adresse email',
                  hint: 'votre@email.com',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Veuillez saisir votre email.';
                    if (!email.contains('@')) return 'Email invalide.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                RoundedTextField(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  obscureText: true,
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (_isSubmitting) return;
                    _submit();
                  },
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return 'Veuillez saisir votre mot de passe.';
                    }
                    if (password.length < 6) {
                      return 'Mot de passe trop court.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isSubmitting ? null : _resetPassword,
            style: TextButton.styleFrom(foregroundColor: AppColors.sunriseDeep),
            child: const Text('Mot de passe oublié ?'),
          ),
        ),
        const SizedBox(height: 6),
        if (_isSubmitting) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: CircularProgressIndicator(),
          ),
        ] else ...[
          PrimaryButton(label: 'Se connecter', onPressed: _submit),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pas encore de compte ? ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () =>
                        Navigator.of(context).pushNamed(UserSignupScreen.route),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.sunriseDeep,
              ),
              child: const Text('S’inscrire'),
            ),
          ],
        ),
      ],
    );
  }
}
