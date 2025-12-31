import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/gradient_shell.dart';
import '../../widgets/inputs.dart';
import '../../widgets/buttons.dart';
import '../../theme/app_colors.dart';
import '../driver_dashboard.dart';
import 'driver_signup.dart';
import '../../services/auth_service.dart';
import '../../models/user_role.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});
  static const String route = '/driver-login';

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _driverCodeController = TextEditingController();
  final _auth = AuthService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _driverCodeController.dispose();
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
      if (role != UserRole.driver) {
        await _auth.signOut();
        throw InvalidUserRoleException(expected: UserRole.driver, actual: role);
      }

      final ok = await _auth.verifyDriverCode(
        uid: uid,
        code: _driverCodeController.text,
      );
      if (!ok) {
        await _auth.signOut();
        throw InvalidDriverCodeException();
      }

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(DriverDashboardScreen.route, (route) => false);
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

  @override
  Widget build(BuildContext context) {
    return GradientShell(
      title: 'Connexion',
      subtitle: 'Espace Chauffeur',
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
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 14),
                RoundedTextField(
                  label: 'Code chauffeur',
                  hint: 'Code à 6 chiffres',
                  controller: _driverCodeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (_isSubmitting) return;
                    _submit();
                  },
                  validator: (value) {
                    final code = (value ?? '').trim();
                    if (code.isEmpty) {
                      return 'Veuillez saisir le code chauffeur.';
                    }
                    if (code.length != 6) {
                      return 'Code invalide (6 chiffres).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_isSubmitting) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: CircularProgressIndicator(),
          ),
        ] else ...[
          PrimaryButton(label: 'Se connecter', onPressed: _submit),
        ],
        const SizedBox(height: 10),
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
                  : () => Navigator.of(
                      context,
                    ).pushNamed(DriverSignupScreen.route),
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
