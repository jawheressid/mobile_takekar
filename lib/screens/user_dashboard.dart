import 'package:flutter/material.dart';
import '../pages/report_problem_page.dart'; // ✅ AJOUT
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cards.dart';
import 'follow_line/follow_line_select.dart';
import 'role_selection.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});
  static const String route = '/user-dashboard';

  @override
  Widget build(BuildContext context) {
    final cards = [
      FeatureCardData(
        'Suivre la ligne',
        'Localisation en temps réel',
        Icons.my_location,
        AppColors.sunrise,
        onTap: () =>
            Navigator.of(context).pushNamed(FollowLineSelectScreen.route),
      ),
      FeatureCardData(
        'Chercher un trajet',
        'Meilleur itinéraire',
        Icons.search,
        AppColors.accentPink,
      ),
      FeatureCardData(
        'Historique',
        'Trajets passés',
        Icons.history,
        AppColors.sunrise,
      ),
      FeatureCardData(
        'Signaler',
        'Rapporter un problème',
        Icons.error_outline,
        AppColors.accentPink,
        onTap: () => Navigator.of(context).pushNamed(ReportProblemPage.route),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                decoration: const BoxDecoration(
                  gradient: sunriseGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'TAKE كار',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bonjour 👋',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        await AuthService().signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RoleSelectionScreen.route,
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cards.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                      itemBuilder: (context, index) =>
                          FeatureCard(data: cards[index]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1AFBC02D),
                            blurRadius: 10,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.sunrise,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Astuce du jour\nSuivez votre bus en temps réel pour ne jamais le manquer',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
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
