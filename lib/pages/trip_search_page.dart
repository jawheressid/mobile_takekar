import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_colors.dart';
import 'trip_results_page.dart';

class TripSearchPage extends StatefulWidget {
  const TripSearchPage({super.key});

  static const String route = '/trip-search';

  @override
  State<TripSearchPage> createState() => _TripSearchPageState();
}

class _TripSearchPageState extends State<TripSearchPage> {
  
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  Position? _fromPosition;
  Position? _toPosition;
  bool _useFromLocation = false;
  bool _useToLocation = false;
  bool _fetchingFromLocation = false;
  bool _fetchingToLocation = false;

  
  final List<(String from, String to)> recentSearches = [
    ('Maison', 'Travail'),
    ('Centre commercial', 'Université'),
  ];

  bool get _canSearch =>
      (_useFromLocation
          ? _fromPosition != null
          : fromController.text.trim().isNotEmpty) &&
      (_useToLocation
          ? _toPosition != null
          : toController.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    
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
    
    final useFromLocation = from == null && _useFromLocation;
    final useToLocation = to == null && _useToLocation;
    final fromValue = useFromLocation
        ? 'Ma position'
        : (from ?? fromController.text).trim();
    final toValue =
        useToLocation ? 'Ma position' : (to ?? toController.text).trim();
    if (fromValue.isEmpty || toValue.isEmpty) return;

    Navigator.of(context).pushNamed(
      TripResultsPage.route,
      arguments: TripResultsArgs(
        fromLabel: fromValue,
        toLabel: toValue,
        fromLat: useFromLocation ? _fromPosition?.latitude : null,
        fromLng: useFromLocation ? _fromPosition?.longitude : null,
        toLat: useToLocation ? _toPosition?.latitude : null,
        toLng: useToLocation ? _toPosition?.longitude : null,
      ),
    );
  }

  Future<Position?> _resolveCurrentPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showSnackBar('Activez la localisation.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showSnackBar('Localisation refusee.');
        return null;
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Autorisez la localisation dans les reglages.');
        return null;
      }
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      _showSnackBar('Impossible de recuperer la position.');
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _setFromLocation() async {
    if (_fetchingFromLocation) return;
    setState(() => _fetchingFromLocation = true);
    final position = await _resolveCurrentPosition();
    if (!mounted) return;
    if (position != null) {
      setState(() {
        _fromPosition = position;
        _useFromLocation = true;
      });
    }
    setState(() => _fetchingFromLocation = false);
  }

  Future<void> _setToLocation() async {
    if (_fetchingToLocation) return;
    setState(() => _fetchingToLocation = true);
    final position = await _resolveCurrentPosition();
    if (!mounted) return;
    if (position != null) {
      setState(() {
        _toPosition = position;
        _useToLocation = true;
      });
    }
    setState(() => _fetchingToLocation = false);
  }

  void _clearFromLocation() {
    setState(() {
      _useFromLocation = false;
      _fromPosition = null;
    });
  }

  void _clearToLocation() {
    setState(() {
      _useToLocation = false;
      _toPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            
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
                    
                    _LabeledField(
                      label: 'Position de départ',
                      child: TextField(
                        controller: fromController,
                        enabled: !_useFromLocation,
                        decoration: InputDecoration(
                          hintText: _useFromLocation
                              ? 'Ma position'
                              : 'Ex: Place de la République',
                          prefixIcon: const Icon(
                            Icons.place,
                            color: Colors.green,
                          ),
                          suffixIcon: _fetchingFromLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: _useFromLocation
                                      ? _clearFromLocation
                                      : _setFromLocation,
                                  icon: Icon(
                                    _useFromLocation
                                        ? Icons.close
                                        : Icons.my_location,
                                  ),
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
                        enabled: !_useToLocation,
                        decoration: InputDecoration(
                          hintText: _useToLocation
                              ? 'Ma position'
                              : 'Ex: Gare centrale',
                          prefixIcon: const Icon(
                            Icons.place,
                            color: Colors.redAccent,
                          ),
                          suffixIcon: _fetchingToLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: _useToLocation
                                      ? _clearToLocation
                                      : _setToLocation,
                                  icon: Icon(
                                    _useToLocation
                                        ? Icons.close
                                        : Icons.my_location,
                                  ),
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
