import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/services/location_service.dart';
import 'package:wayfinder/services/voice_service.dart';
import 'package:wayfinder/services/nominatim_service.dart';
import 'package:wayfinder/models/map_suggestion.dart';
import 'package:wayfinder/services/routing_service.dart';
import 'package:wayfinder/services/saved_place_service.dart';
import 'package:wayfinder/models/saved_place.dart';
import 'package:wayfinder/services/collection_service.dart';
import 'package:wayfinder/services/place_service.dart';
import 'package:wayfinder/services/search_service.dart';
import 'package:wayfinder/models/search_history.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wayfinder/services/alert_service.dart';
import 'package:wayfinder/models/travel_alert.dart';
import 'package:wayfinder/models/place.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  final double? initialTargetLat;
  final double? initialTargetLon;
  final String? initialTargetTitle;
  final bool autoRoute;

  const MapPage({super.key, this.initialTargetLat, this.initialTargetLon, this.initialTargetTitle, this.autoRoute = false});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final VoiceService _voiceService = VoiceService();
  final NominatimService _nominatimService = NominatimService();
  final RoutingService _routingService = RoutingService();
  final SavedPlaceService _savedService = SavedPlaceService();
  final CollectionService _collectionService = CollectionService();
  final PlaceService _placeService = PlaceService();
  final SearchService _searchService = SearchService();
  final AlertService _alertService = AlertService();
  LatLng _initialPosition = LatLng(12.9407, 77.5572);
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  double _zoom = 14;
  List<MapSuggestion> _suggestions = [];
  LatLng? _searchTarget;
  bool _searching = false;
  DateTime _lastQueryAt = DateTime.fromMillisecondsSinceEpoch(0);
  List<LatLng> _routePoints = [];
  double? _routeKm;
  double? _routeMin;
  bool _routing = false;
  double _radiusKm = 5;
  bool _showRestaurants = true;
  bool _showAttractions = true;
  bool _showHospitals = true;
  List<Place> _nearby = [];
  List<SearchHistory> _recent = [];
  bool _smartSuggestionsEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadRecentSearches();
    // If launched with a destination, set it up
    if (widget.initialTargetLat != null && widget.initialTargetLon != null) {
      _searchTarget = LatLng(widget.initialTargetLat!, widget.initialTargetLon!);
      if (widget.initialTargetTitle != null) {
        _searchController.text = widget.initialTargetTitle!;
      }
      // Optionally auto route after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          _mapController.move(_searchTarget!, 16);
        } catch (e) {
          debugPrint('Move to initial target failed: $e');
        }
        if (widget.autoRoute) await _buildRoute();
      });
    }
  }

  Future<void> _buildRoute() async {
    if (_searchTarget == null) return;
    setState(() => _routing = true);
    final res = await _routingService.getRoute(_initialPosition, _searchTarget!);
    setState(() {
      _routing = false;
      if (res != null) {
        _routePoints = res.points;
        _routeKm = res.distanceKm;
        _routeMin = res.durationMin;
      } else {
        _routePoints = [];
        _routeKm = null;
        _routeMin = null;
      }
    });
    // Announce navigation start with TTS (female voice preference configured in VoiceService)
    try {
      if (res != null) {
        if (!_voiceService.isInitialized) {
          await _voiceService.initialize();
        }
        final title = _searchController.text.isNotEmpty ? _searchController.text : 'your destination';
        await _voiceService.speak('Starting navigation to $title. ${res.durationMin.toStringAsFixed(0)} minutes for ${res.distanceKm.toStringAsFixed(1)} kilometers.');
        if (res.steps.isNotEmpty) {
          final first = res.steps.first;
          await _voiceService.speak('Then, ${first.instruction} for ${(first.distanceMeters / 1000).toStringAsFixed(first.distanceMeters < 950 ? 1 : 0)} ${first.distanceMeters < 950 ? 'kilometers' : 'kilometer'}');
        }
      }
    } catch (e) {
      debugPrint('TTS announce failed: $e');
    }
    // Smart, friendly suggestion for cheaper transport
    if (_smartSuggestionsEnabled && _routeKm != null && mounted) {
      String tip;
      if (_routeKm! >= 3 && _routeKm! <= 15) {
        tip = 'Tip: Public transit may be cheaper for ${_routeKm!.toStringAsFixed(1)} km.';
      } else if (_routeKm! < 3) {
        tip = 'Tip: Consider walking or a bike for short trips.';
      } else {
        tip = 'Tip: For longer trips, check bus/rail to save money.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tip)));
    }
  }

  Future<void> _openFiltersSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: AppSpacing.sm),
                Text('Filters', style: context.textStyles.titleLarge),
              ]),
              SizedBox(height: AppSpacing.md),
              Text('Show nearby categories', style: context.textStyles.titleMedium),
              SizedBox(height: AppSpacing.sm),
              Wrap(spacing: 8, children: [
                FilterChip(label: Text('Restaurants'), selected: _showRestaurants, onSelected: (v) => setState(() => _showRestaurants = v)),
                FilterChip(label: Text('Attractions'), selected: _showAttractions, onSelected: (v) => setState(() => _showAttractions = v)),
                FilterChip(label: Text('Hospitals'), selected: _showHospitals, onSelected: (v) => setState(() => _showHospitals = v)),
              ]),
              SizedBox(height: AppSpacing.md),
              Row(children: [
                Text('Radius: ${_radiusKm.toStringAsFixed(0)} km'),
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 25,
                    divisions: 24,
                    label: '${_radiusKm.toStringAsFixed(0)} km',
                    onChanged: (v) => setState(() => _radiusKm = v),
                  ),
                ),
              ]),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.check),
                  label: Text('Apply'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _computeNearby() async {
    final List<Place> results = [];
    if (_showRestaurants) {
      results.addAll(await _placeService.getNearbyPlaces(_initialPosition.latitude, _initialPosition.longitude, type: PlaceType.restaurant, maxDistanceKm: _radiusKm));
    }
    if (_showAttractions) {
      results.addAll(await _placeService.getNearbyPlaces(_initialPosition.latitude, _initialPosition.longitude, type: PlaceType.attraction, maxDistanceKm: _radiusKm));
    }
    if (_showHospitals) {
      results.addAll(await _placeService.getNearbyPlaces(_initialPosition.latitude, _initialPosition.longitude, type: PlaceType.hospital, maxDistanceKm: _radiusKm));
    }
    // De-dupe by id
    final map = {for (final p in results) p.id: p};
    setState(() => _nearby = map.values.toList());
  }

  Future<void> _saveCurrentTarget() async {
    if (_searchTarget == null) return;
    final userId = 'local_user';
    final id = 'saved_${DateTime.now().millisecondsSinceEpoch}';
    final place = SavedPlace(
      id: id,
      userId: userId,
      placeId: id,
      placeName: _searchController.text,
      address: _searchController.text,
      latitude: _searchTarget!.latitude,
      longitude: _searchTarget!.longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _savedService.addSavedPlace(place);
    final collections = await _collectionService.getCollections(userId);
    if (collections.isEmpty) {
      final fav = await _collectionService.ensureDefaultFavorites(userId);
      await _collectionService.addPlaceToCollection(collectionId: fav.id, place: place);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${fav.name}')));
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (context) => Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Save to collection', style: context.textStyles.titleLarge),
          SizedBox(height: AppSpacing.md),
          ...collections.map((c) => ListTile(
                leading: Icon(Icons.folder),
                title: Text(c.name),
                onTap: () async {
                  await _collectionService.addPlaceToCollection(collectionId: c.id, place: place);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${c.name}')));
                },
              )),
        ]),
      ),
    );
  }

  Future<void> _initializeLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      try {
        _mapController.move(_initialPosition, _zoom);
      } catch (e) {
        debugPrint('Map move before ready: $e');
      }
      await _checkGeofences();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final items = await _searchService.getSearchHistory('local_user');
      if (mounted) setState(() => _recent = items);
    } catch (e) {
      debugPrint('Load recent error: $e');
    }
  }

  Future<void> _shareMyLocation() async {
    final url = 'https://www.openstreetmap.org/?mlat=${_initialPosition.latitude.toStringAsFixed(6)}&mlon=${_initialPosition.longitude.toStringAsFixed(6)}#map=${_zoom.toStringAsFixed(0)},${_initialPosition.latitude.toStringAsFixed(6)},${_initialPosition.longitude.toStringAsFixed(6)}';
    try {
      await Share.share('My live location: $url');
    } catch (e) {
      debugPrint('Share failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open share sheet')));
    }
  }

  Future<void> _checkGeofences() async {
    try {
      final alerts = await _alertService.getActiveAlerts('user1');
      for (final a in alerts) {
        final distKm = Place(id: 'tmp', name: '', address: '', latitude: a.latitude, longitude: a.longitude, type: PlaceType.general, createdAt: DateTime.now(), updatedAt: DateTime.now()).distanceFrom(_initialPosition.latitude, _initialPosition.longitude);
        if (distKm * 1000 <= a.radiusMeters) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You're near ${a.placeName} (${a.radiusMeters.toInt()}m)")));
        }
      }
    } catch (e) {
      debugPrint('Geofence check failed: $e');
    }
  }

  void _openRidesSheet() {
    if (_searchTarget == null) return;
    final dropLat = _searchTarget!.latitude;
    final dropLon = _searchTarget!.longitude;
    final pickLat = _initialPosition.latitude;
    final pickLon = _initialPosition.longitude;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (context) => Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.local_taxi, color: Theme.of(context).colorScheme.primary), SizedBox(width: AppSpacing.sm), Text('Rides', style: context.textStyles.titleLarge)]),
            SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Uber'),
              onTap: () async {
                final uri = Uri.parse('uber://?action=setPickup&pickup=my_location&dropoff[latitude]=$dropLat&dropoff[longitude]=$dropLon');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_taxi),
              title: const Text('Ola'),
              onTap: () async {
                final uri = Uri.parse('olacabs://app/launch?lat=$pickLat&lng=$pickLon&drop_lat=$dropLat&drop_lng=$dropLon');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAutocomplete(String q) async {
    final now = DateTime.now();
    // simple throttle: only query if >250ms passed
    if (now.difference(_lastQueryAt).inMilliseconds < 250) return;
    _lastQueryAt = now;
    if (q.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    final res = await _nominatimService.search(q, limit: 8);
    setState(() {
      _suggestions = res;
      _searching = false;
    });
  }

  Future<void> _selectSuggestion(MapSuggestion s) async {
    setState(() {
      _searchController.text = s.title;
      _suggestions = [];
      _searchTarget = LatLng(s.lat, s.lon);
      _routePoints = [];
      _routeKm = null;
      _routeMin = null;
    });
    try {
      _mapController.move(_searchTarget!, 16);
    } catch (e) {
      debugPrint('Move to suggestion failed: $e');
    }
    // Save to search history
    try {
      await _searchService.addSearchHistory(SearchHistory(
        id: 'h_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'local_user',
        searchQuery: s.title,
        createdAt: DateTime.now(),
      ));
      await _loadRecentSearches();
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  Future<void> _toggleVoice() async {
    if (!_voiceService.isInitialized) {
      final ok = await _voiceService.initialize();
      if (!ok) return;
    }
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      return;
    }
    await _voiceService.speak('Listening. Say a place or address');
    await _voiceService.startListening(onResult: (text) async {
      if (!mounted) return;
      setState(() => _searchController.text = text);
      await _voiceService.speak('Searching for $text');
      await _runAutocomplete(text);
      if (_suggestions.isNotEmpty) {
        await _selectSuggestion(_suggestions.first);
        await _voiceService.speak('Showing ${_suggestions.first.title}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.golden))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialPosition,
                    initialZoom: _zoom,
                    interactionOptions: const InteractionOptions(
                      enableMultiFingerGestureRace: true,
                    ),
                    onMapEvent: (event) {
                      // Keep our zoom in sync
                      _zoom = event.camera.zoom;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'wayfinder',
                      tileBounds: LatLngBounds(
                        LatLng(-85.05112878, -180.0),
                        LatLng(85.05112878, 180.0),
                      ),
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(polylines: [
                        Polyline(points: _routePoints, color: Theme.of(context).colorScheme.primary, strokeWidth: 4),
                      ]),
                    if (_nearby.isNotEmpty)
                      MarkerLayer(
                        markers: _nearby
                            .map((p) => Marker(
                                  point: LatLng(p.latitude, p.longitude),
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.bottomCenter,
                                  child: GestureDetector(
                                    onTap: () => _selectSuggestion(MapSuggestion(title: p.name, subtitle: p.address, lat: p.latitude, lon: p.longitude)),
                                    child: Icon(Icons.location_on, size: 30, color: Theme.of(context).colorScheme.tertiary),
                                  ),
                                ))
                            .toList(),
                      ),
                    MarkerLayer(markers: [
                      Marker(
                        point: _initialPosition,
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onPrimary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.my_location, size: 18, color: Colors.white),
                        ),
                      ),
                    ]),
                    if (_searchTarget != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _searchTarget!,
                          width: 36,
                          height: 36,
                          alignment: Alignment.bottomCenter,
                          child: Icon(Icons.location_pin, size: 36, color: Theme.of(context).colorScheme.primary),
                        ),
                      ]),
                  ],
                ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.search, color: Colors.white70),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: TextField(
                            controller: _searchController,
                                      onChanged: _runAutocomplete,
                                      decoration: InputDecoration(
                                        hintText: 'Search for places...'
                                            ,
                                        border: InputBorder.none,
                                        hintStyle: context.textStyles.bodyMedium?.copyWith(color: Colors.white70),
                                      ),
                                      style: context.textStyles.bodyMedium?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(_voiceService.isListening ? Icons.mic : Icons.mic_none, color: Theme.of(context).colorScheme.primary),
                                    onPressed: _toggleVoice,
                                    tooltip: 'Voice search',
                                  ),
                                ],
                              ),
                              if (_searching) ...[
                                SizedBox(height: AppSpacing.xs),
                                LinearProgressIndicator(minHeight: 2, color: Theme.of(context).colorScheme.primary),
                              ],
                              if (_suggestions.isNotEmpty) ...[
                                SizedBox(height: AppSpacing.xs),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  constraints: BoxConstraints(maxHeight: 220),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: _suggestions.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                                    itemBuilder: (context, index) {
                                      final s = _suggestions[index];
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(Icons.place, color: Colors.white70),
                                        title: Text(s.title, style: context.textStyles.bodyMedium?.copyWith(color: Colors.white)),
                                        subtitle: s.subtitle.isNotEmpty ? Text(s.subtitle, style: context.textStyles.labelSmall?.copyWith(color: Colors.white70)) : null,
                                        onTap: () => _selectSuggestion(s),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () async {
                            await _openFiltersSheet();
                            await _computeNearby();
                          },
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.share_location, color: Theme.of(context).colorScheme.onSurface),
                          onPressed: _shareMyLocation,
                        ),
                      ),
                    ],
                  ),
                ),
                // Recent searches chip row removed per request
              ],
            ),
          ),
          if (_searchTarget != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 24,
              child: Column(
                children: [
                  if (_routeKm != null && _routeMin != null)
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2))),
                      child: Row(children: [
                        Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: Text('${_routeKm!.toStringAsFixed(1)} km · ${_routeMin!.toStringAsFixed(0)} min')),
                        IconButton(onPressed: _saveCurrentTarget, icon: Icon(Icons.bookmark_add, color: Theme.of(context).colorScheme.primary)),
                      ]),
                    ),
                  SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _routing ? null : _buildRoute,
                        icon: Icon(Icons.directions),
                        label: Text(_routing ? 'Fetching route...' : 'Directions'),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _openRidesSheet,
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface, foregroundColor: Theme.of(context).colorScheme.onSurface),
                      child: const Icon(Icons.local_taxi),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _saveCurrentTarget,
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface, foregroundColor: Theme.of(context).colorScheme.onSurface),
                      child: Icon(Icons.bookmark_add),
                    ),
                  ]),
                ],
              ),
            ),
          Positioned(
            right: AppSpacing.md,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPressed: () {
                    try {
                      _zoom = (_zoom + 1).clamp(1, 19);
                      _mapController.move(_initialPosition, _zoom);
                    } catch (e) {
                      debugPrint('Zoom in failed: $e');
                    }
                  },
                  child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface),
                ),
                SizedBox(height: AppSpacing.sm),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPressed: () {
                    try {
                      _zoom = (_zoom - 1).clamp(1, 19);
                      _mapController.move(_initialPosition, _zoom);
                    } catch (e) {
                      debugPrint('Zoom out failed: $e');
                    }
                  },
                  child: Icon(Icons.remove, color: Theme.of(context).colorScheme.onSurface),
                ),
                SizedBox(height: AppSpacing.sm),
                FloatingActionButton(
                  heroTag: 'location',
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPressed: _initializeLocation,
                  child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}
