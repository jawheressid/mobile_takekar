import 'package:flutter/material.dart';

import '../../services/follow_line_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons.dart';
import 'line_tracking.dart';

class FollowLineSelectScreen extends StatefulWidget {
  const FollowLineSelectScreen({super.key});
  static const String route = '/follow-line';

  @override
  State<FollowLineSelectScreen> createState() => _FollowLineSelectScreenState();
}

class _FollowLineSelectScreenState extends State<FollowLineSelectScreen> {
  final _service = FollowLineService();

  String? _selectedLine;
  String? _selectedRegion;
  late Future<List<String>> _linesFuture;
  Future<List<String>>? _regionsFuture;

  @override
  void initState() {
    super.initState();
    _linesFuture = _service.fetchLines();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedLine != null && _selectedRegion != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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
                    'Suivre la ligne',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text('Localisez votre bus', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DropdownCard(
                      child: FutureBuilder<List<String>>(
                        future: _linesFuture,
                        builder: (context, snapshot) {
                          final lines = snapshot.data ?? const <String>[];
                          return DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLine,
                              hint: const Text('Sélectionnez une ligne'),
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(14),
                              items: lines
                                  .map((e) => DropdownMenuItem<String>(
                                        value: e,
                                        child: Text(e),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLine = value;
                                  _selectedRegion = null;
                                  _regionsFuture = value == null ? null : _service.fetchRegions(lineName: value);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Région', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                    const SizedBox(height: 6),
                    _DropdownCard(
                      child: FutureBuilder<List<String>>(
                        future: _regionsFuture,
                        builder: (context, snapshot) {
                          final regions = snapshot.data ?? const <String>[];
                          final enabled = _selectedLine != null;
                          return DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRegion,
                              hint: const Text('Sélectionnez une région'),
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(14),
                              items: regions
                                  .map((e) => DropdownMenuItem<String>(
                                        value: e,
                                        child: Text(e),
                                      ))
                                  .toList(),
                              onChanged: enabled ? (value) => setState(() => _selectedRegion = value) : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: canContinue ? 1 : 0.5,
                      child: PrimaryButton(
                        label: 'Voir la localisation',
                        onPressed: canContinue
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LineTrackingScreen(
                                      lineName: _selectedLine!,
                                      regionName: _selectedRegion!,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
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
                          Icon(Icons.push_pin, color: AppColors.accentPink, size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Information\nSélectionnez votre ligne et région pour voir la position exacte du bus',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _DropdownCard extends StatelessWidget {
  const _DropdownCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

