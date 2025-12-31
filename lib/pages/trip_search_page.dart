import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'trip_results_page.dart';

class TripSearchPage extends StatefulWidget {
  const TripSearchPage({super.key});

  static const String route = '/trip-search';

  @override
  State<TripSearchPage> createState() => _TripSearchPageState();
}

class _TripSearchPageState extends State<TripSearchPage> {
  // Contrôleurs des champs "Départ" et "Arrivée"
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  // Exemple simple de recherches récentes (pas de stockage local pour l’instant).
  final List<(String from, String to)> recentSearches = [
    ('Maison', 'Travail'),
    ('Centre commercial', 'Université'),
  ];

  bool get _canSearch =>
      fromController.text.trim().isNotEmpty &&
      toController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // On rebuild quand l’utilisateur tape, pour activer/désactiver le bouton.
    fromController.addListener(() => setState(() {}));
    toController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  void _search({String? from, String? to}) {
    // On prend soit les valeurs passées (recherches récentes), soit celles des champs.
    final fromValue = (from ?? fromController.text).trim();
    final toValue = (to ?? toController.text).trim();
    if (fromValue.isEmpty || toValue.isEmpty) return;

    Navigator.of(context).pushNamed(
      TripResultsPage.route,
      arguments: TripResultsArgs(from: fromValue, to: toValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header jaune comme l’image (avec retour).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
              decoration: const BoxDecoration(
                gradient: sunriseGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chercher le bon trajet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Trouvez le meilleur itinéraire",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Formulaire
                    _LabeledField(
                      label: 'Position de départ',
                      child: TextField(
                        controller: fromController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Place de la République',
                          prefixIcon: const Icon(
                            Icons.place,
                            color: Colors.green,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: "Position d'arrivée",
                      child: TextField(
                        controller: toController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Gare centrale',
                          prefixIcon: const Icon(
                            Icons.place,
                            color: Colors.redAccent,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Bouton de recherche
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _canSearch ? () => _search() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSearch
                              ? AppColors.sunrise
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Chercher'),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Recherches récentes (UI simple)
                    const Text(
                      'Recherches récentes',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recentSearches.map(
                      (s) => _RecentSearchTile(
                        from: s.$1,
                        to: s.$2,
                        onTap: () => _search(from: s.$1, to: s.$2),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({
    required this.from,
    required this.to,
    required this.onTap,
  });

  final String from;
  final String to;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.place, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      from,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      to,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
