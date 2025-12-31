import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../widgets/inputs.dart';
import '../widgets/cards.dart';
import 'follow_line/follow_line_page.dart';
import 'role_selection.dart';
import '../services/auth_service.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  static const String route = '/driver-dashboard';

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final List<String> lines = ['Ligne 1', 'Ligne 2', 'Ligne 3'];
  String? selectedLine;
  final _busController = TextEditingController(text: 'BUS-2025-001');

  @override
  void dispose() {
    _busController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: const BoxDecoration(
                  gradient: sunriseGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 6),
                    Text('Tableau de bord', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('Commencez votre service', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Identifiant du bus (ex: plaque / code interne).
                    // On le garde très simple: un champ texte modifiable.
                    RoundedTextField(label: 'Bus', hint: 'BUS-2025-001', controller: _busController),
                    const SizedBox(height: 14),
                    const Text('Numéro de ligne', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1AFBC02D),
                            blurRadius: 10,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLine,
                          hint: const Text('Sélectionnez votre ligne'),
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(14),
                          items: lines
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => selectedLine = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Commencer le service',
                      onPressed: () {
                        // Règle métier simple:
                        // - le chauffeur doit choisir une ligne
                        // - ensuite on ouvre l'écran "FollowLinePage" (en service)
                        if (selectedLine == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez sélectionner une ligne.')),
                          );
                          return;
                        }

                        final busId = _busController.text.trim().isEmpty ? 'BUS-2025-001' : _busController.text.trim();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FollowLinePage(
                              lineName: selectedLine!,
                              busId: busId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        StatsCard(label: 'Trajets effectués', value: '0'),
                        StatsCard(label: 'Temps de service', value: '0h'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(RoleSelectionScreen.route, (route) => false);
                      },
                      icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                      label: const Text('Déconnexion', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
