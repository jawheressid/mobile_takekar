import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/gradient_shell.dart';
import '../../widgets/inputs.dart';
import '../../widgets/buttons.dart';
import '../../theme/app_colors.dart';
import 'driver_login.dart';
import '../../services/auth_service.dart';
import '../../models/user_role.dart';

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});
  static const String route = '/driver-signup';

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _driverCodeController = TextEditingController();
  final _busNumberController = TextEditingController();
  final _auth = AuthService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _driverCodeController.dispose();
    _busNumberController.dispose();
    super.dispose();
  }

  String _normalizedEmail() => _emailController.text.trim().toLowerCase();

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final credential = await _auth.createUserWithEmailPassword(
        email: _normalizedEmail(),
        password: _passwordController.text,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception('Missing uid');
      }

      final fullName = _fullNameController.text.trim();
      if (fullName.isNotEmpty) {
        await credential.user?.updateDisplayName(fullName);
      }

      await _auth.upsertUserProfile(
        uid: uid,
        role: UserRole.driver,
        fullName: fullName.isEmpty ? null : fullName,
        driverCode: _driverCodeController.text.trim(),
        busNumber: _busNumberController.text.trim(),
      );
      await _auth.upsertDriverProfile(
        uid: uid,
        name: fullName,
        allowedBusIds: const <int>[],
      );

      if (!(credential.user?.emailVerified ?? false)) {
        await credential.user?.sendEmailVerification();
      }
      await _auth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Un email de verification a ete envoye. Verifiez votre boite mail.',
          ),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        DriverLoginScreen.route,
        (route) => false,
      );
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
      title: 'Inscription',
      subtitle: 'Espace Chauffeur',
      onBack: _isSubmitting ? null : () => Navigator.of(context).pop(),
      children: [
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                RoundedTextField(
                  label: 'Nom complet',
                  hint: 'Votre nom',
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) {
                    final name = (value ?? '').trim();
                    if (name.isEmpty) return 'Veuillez saisir votre nom.';
                    if (name.length < 2) return 'Nom trop court.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
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
                    if (!isValidEmail(email)) return 'Email invalide.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                RoundedTextField(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  obscureText: true,
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return 'Veuillez saisir un mot de passe.';
                    }
                    if (password.length < 6) {
                      return '6 caractères minimum.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                RoundedTextField(
                  label: 'Confirmer le mot de passe',
                  hint: '••••••••',
                  obscureText: true,
                  controller: _confirmPasswordController,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final confirm = value ?? '';
                    if (confirm.isEmpty) {
                      return 'Veuillez confirmer le mot de passe.';
                    }
                    if (confirm != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas.';
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
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 14),
                RoundedTextField(
                  label: 'Numéro de bus',
                  hint: 'BUS-2025-001',
                  controller: _busNumberController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (_isSubmitting) return;
                    _submit();
                  },
                  validator: (value) {
                    final bus = (value ?? '').trim();
                    if (bus.isEmpty) return 'Veuillez saisir le numéro de bus.';
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
          PrimaryButton(label: 'Créer le compte', onPressed: _submit),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Déjà inscrit ? ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pushReplacementNamed(DriverLoginScreen.route),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ],
    );
  }
}
