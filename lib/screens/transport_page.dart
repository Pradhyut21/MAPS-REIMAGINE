import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/services/location_service.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:wayfinder/services/nominatim_service.dart';
import 'package:wayfinder/models/map_suggestion.dart';
import 'package:wayfinder/widgets/app_background.dart';
import 'package:wayfinder/widgets/live_image_header.dart';
import 'package:wayfinder/services/overpass_service.dart';
import 'package:wayfinder/nav.dart';

class TransportPage extends StatefulWidget {
  final String? destination;

  const TransportPage({super.key, this.destination});

  @override
  State<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  final LocationService _locationService = LocationService();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final NominatimService _nominatim = NominatimService();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();
  final OverpassService _overpass = OverpassService();
  
  double? _userLat;
  double? _userLon;
  bool _isLoading = false;
  bool _searchingFrom = false;
  bool _searchingTo = false;
  DateTime _lastFromAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastToAt = DateTime.fromMillisecondsSinceEpoch(0);
  List<MapSuggestion> _fromSuggestions = [];
  List<MapSuggestion> _toSuggestions = [];
  MapSuggestion? _selectedFrom;
  MapSuggestion? _selectedTo;
  List<BusPlatform> _platforms = [];
  BusPlatform? _suggestedStand;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    if (widget.destination != null) {
      _toController.text = widget.destination!;
    }
  }

  Future<void> _loadLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _userLat = position.latitude;
        _userLon = position.longitude;
      });
    } else {
      final defaultPos = LocationService.getDefaultPosition();
      setState(() {
        _userLat = defaultPos.latitude;
        _userLon = defaultPos.longitude;
      });
    }
    // Suggest a stand based on current location initially
    if (_userLat != null && _userLon != null) {
      _loadSuggestedStand(_userLat!, _userLon!);
    }
  }

  void _showRoute() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both from and to locations'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      return;
    }

    // Show cheaper transport tip
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tip: Buses are often the cheapest option on this route.')),
    );
    // If we have coordinates for destination, fetch platforms nearby
    if (_selectedTo != null) {
      _loadPlatforms(_selectedTo!.lat, _selectedTo!.lon);
    }
  }

  Future<void> _loadPlatforms(double lat, double lon) async {
    setState(() => _isLoading = true);
    final res = await _overpass.getNearbyBusPlatforms(lat, lon);
    setState(() {
      _platforms = res;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  Future<void> _queryFrom(String q) async {
    final now = DateTime.now();
    if (now.difference(_lastFromAt).inMilliseconds < 250) return;
    _lastFromAt = now;
    if (q.trim().isEmpty) {
      setState(() => _fromSuggestions = []);
      return;
    }
    setState(() => _searchingFrom = true);
    final res = await _nominatim.search(q, limit: 6);
    setState(() {
      _fromSuggestions = res;
      _searchingFrom = false;
    });
  }

  Future<void> _queryTo(String q) async {
    final now = DateTime.now();
    if (now.difference(_lastToAt).inMilliseconds < 250) return;
    _lastToAt = now;
    if (q.trim().isEmpty) {
      setState(() => _toSuggestions = []);
      return;
    }
    setState(() => _searchingTo = true);
    final res = await _nominatim.search(q, limit: 6);
    setState(() {
      _toSuggestions = res;
      _searchingTo = false;
    });
  }

  Future<void> _loadSuggestedStand(double lat, double lon) async {
    try {
      final station = await _overpass.getNearestBusStation(lat, lon);
      setState(() => _suggestedStand = station);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bus',
          style: context.textStyles.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
      body: AppGradientBackground(
        child: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiveImageHeader(images: const [
              'assets/images/Modern_bus_station_platform_blue_1767253932524.jpg',
              'assets/images/Airport_terminal_modern_architecture_gray_1767253937220.jpg',
              'assets/images/Urban_map_aerial_city_blocks_black_1767253938714.jpg',
            ], height: 160),
            SizedBox(height: AppSpacing.md),
            Text(
              'Bus / Route Helper',
              style: context.textStyles.headlineSmall?.copyWith(color: Colors.white),
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.golden, size: 16),
                SizedBox(width: AppSpacing.xs),
                Text(
                  '${_userLat?.toStringAsFixed(4)}, ${_userLon?.toStringAsFixed(4)}',
                  style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(color: AppColors.brownCard, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Enter from and to locations to see map directions (can be used like KSRTC route helper).', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.lightGray)),
                SizedBox(height: AppSpacing.lg),
                // From chip / input
                _RouteChipField(
                  label: 'From',
                  controller: _fromController,
                  focusNode: _fromFocus,
                  searching: _searchingFrom,
                  suggestions: _fromSuggestions,
                  onChanged: _queryFrom,
                  onSelect: (s) {
                    setState(() {
                      _fromController.text = s.title;
                      _fromSuggestions = [];
                      _selectedFrom = s;
                    });
                    _loadSuggestedStand(s.lat, s.lon);
                    _toFocus.requestFocus();
                  },
                ),
                SizedBox(height: AppSpacing.md),
                _RouteChipField(
                  label: 'To',
                  controller: _toController,
                  focusNode: _toFocus,
                  searching: _searchingTo,
                  suggestions: _toSuggestions,
                  onChanged: _queryTo,
                  onSelect: (s) {
                    setState(() {
                      _toController.text = s.title;
                      _toSuggestions = [];
                      _selectedTo = s;
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
                if (_suggestedStand != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text('Suggested stand: ${_suggestedStand!.name}', style: context.textStyles.labelSmall?.copyWith(color: AppColors.lightGray)),
                ],
                SizedBox(height: AppSpacing.lg),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _showRoute,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, padding: EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
                  child: Text('Show Route', style: context.textStyles.titleMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                )),
                SizedBox(height: AppSpacing.md),
                if (_selectedFrom != null && _selectedTo != null) ...[
                  _RouteSteps(
                    from: _selectedFrom!,
                    to: _selectedTo!,
                    suggestedStand: _suggestedStand?.name,
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
                if (_selectedTo != null) SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: () {
                    final t = Uri.encodeComponent(_selectedTo!.title);
                    context.push('${AppRoutes.map}?lat=${_selectedTo!.lat}&lon=${_selectedTo!.lon}&title=$t&autoroute=true');
                  },
                  icon: Icon(Icons.navigation, color: Colors.black),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, padding: EdgeInsets.symmetric(vertical: AppSpacing.md), shape: StadiumBorder()),
                  label: Text('Open Directions in Map', style: context.textStyles.titleSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w600)),
                )),
              ]),
            ),
            if (_platforms.isNotEmpty) ...[
              SizedBox(height: AppSpacing.lg),
              Text('Platforms near destination', style: context.textStyles.titleMedium?.copyWith(color: Colors.white)),
              SizedBox(height: AppSpacing.sm),
              ..._platforms.take(6).map((p) => Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(color: AppColors.darkBrown, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Row(children: [
                      Icon(Icons.directions_bus, color: AppColors.golden),
                      SizedBox(width: AppSpacing.md),
                      Expanded(child: Text('${p.name}${p.ref != null ? ' (${p.ref})' : ''}', style: context.textStyles.bodyMedium?.copyWith(color: Colors.white))),
                    ]),
                  )),
            ],
          ],
        ),
      ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4),
    );
  }
}

class _RouteChipField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final List<MapSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<MapSuggestion> onSelect;

  const _RouteChipField({required this.label, required this.controller, required this.focusNode, required this.searching, required this.suggestions, required this.onChanged, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.darkBrown, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (controller.text.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Row(children: [
              Icon(Icons.place, color: Colors.white70, size: 18),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(controller.text, style: context.textStyles.bodyMedium?.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis)),
              GestureDetector(onTap: () { controller.clear(); focusNode.requestFocus(); }, child: Icon(Icons.close, color: Colors.white70, size: 18)),
            ]),
          )
        else
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            decoration: InputDecoration(hintText: '$label (e.g., Mysore)', border: InputBorder.none, hintStyle: context.textStyles.bodyMedium?.copyWith(color: AppColors.lightGray)),
            style: context.textStyles.bodyMedium?.copyWith(color: Colors.white),
          ),
        if (searching) LinearProgressIndicator(minHeight: 2, color: AppColors.golden),
        if (suggestions.isNotEmpty && focusNode.hasFocus)
          Container(
            constraints: BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              itemBuilder: (context, i) {
                final s = suggestions[i];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.place, color: AppColors.lightGray),
                  title: Text(s.title, style: context.textStyles.bodyMedium?.copyWith(color: Colors.white)),
                  subtitle: s.subtitle.isNotEmpty ? Text(s.subtitle, style: context.textStyles.labelSmall?.copyWith(color: AppColors.lightGray)) : null,
                  onTap: () => onSelect(s),
                );
              },
            ),
          ),
      ]),
    );
  }
}

class _RouteSteps extends StatelessWidget {
  final MapSuggestion from;
  final MapSuggestion to;
  final String? suggestedStand;

  const _RouteSteps({required this.from, required this.to, this.suggestedStand});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepText(context, 1, 'Choose your route: From: ${from.title} → To: ${to.title}'),
      _stepText(context, 2, 'Go to the bus stand: From ${from.title}, go to: ${suggestedStand ?? 'nearest city bus stand'}.'),
      _stepText(context, 3, 'Platform / Bay details: Ask at the enquiry counter for the platform/bay towards ${to.title}. Platform numbers can change.'),
      _stepText(context, 4, 'Ticket + boarding: Operator may be KSRTC / State RTC / Private. Take a ticket (or show booking) and board. Reach 20–30 minutes early for platform confirmation.'),
      _stepText(context, 5, 'Arrival: Get down at ${to.title} and follow local sign boards to reach your exact spot.'),
    ]);
  }

  Widget _stepText(BuildContext context, int step, String text) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text('Step $step: $text', style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray)),
      );
}
