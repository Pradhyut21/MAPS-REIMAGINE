import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/models/place.dart';
import 'package:wayfinder/services/place_service.dart';
import 'package:wayfinder/services/location_service.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:wayfinder/widgets/live_image_header.dart';
import 'package:wayfinder/nav.dart';
import 'package:wayfinder/widgets/app_background.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final PlaceService _placeService = PlaceService();
  final LocationService _locationService = LocationService();
  
  List<Place> _hospitals = [];
  List<Place> _policeStations = [];
  bool _isLoading = true;
  double? _userLat;
  double? _userLon;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _userLat = position.latitude;
      _userLon = position.longitude;
    } else {
      final defaultPos = LocationService.getDefaultPosition();
      _userLat = defaultPos.latitude;
      _userLon = defaultPos.longitude;
    }

    final hospitals = await _placeService.getPlacesByType(PlaceType.hospital);
    final police = await _placeService.getPlacesByType(PlaceType.police);
    
    if (_userLat != null && _userLon != null) {
      hospitals.sort((a, b) => 
        a.distanceFrom(_userLat!, _userLon!).compareTo(b.distanceFrom(_userLat!, _userLon!))
      );
      police.sort((a, b) => 
        a.distanceFrom(_userLat!, _userLon!).compareTo(b.distanceFrom(_userLat!, _userLon!))
      );
    }

    setState(() {
      _hospitals = hospitals;
      _policeStations = police;
      _isLoading = false;
    });
  }

  void _callEmergency() {
    // Directly dial the universal emergency number. On web, this opens the dialer.
    final uri = Uri.parse('tel:112');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _shareLocation() {
    if (_userLat == null || _userLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location not available'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      return;
    }

    final locationUrl = 'https://www.google.com/maps?q=$_userLat,$_userLon';
    final message = 'My current location: $locationUrl';
    
    final smsUrl = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
    launchUrl(smsUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: AppGradientBackground(
        child: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.golden))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.emergencyRed,
                  expandedHeight: 120,
                  pinned: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Emergency',
                      style: context.textStyles.titleLarge?.copyWith(color: Colors.white),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.emergencyRed, AppColors.darkRed],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: LiveImageHeader(images: const [
                      'assets/images/Emergency_services_3D_ambulance_neon_red_1767254944561.jpg',
                      'assets/images/3D_emergency_services_icons_ambulance_police_hospital_isometric_red_1767255110463.jpg',
                      'assets/images/hospital_medical_emergency_null_1767249777516.jpg',
                    ], height: 160),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _callEmergency,
                                icon: Icon(Icons.warning, color: Colors.white),
                                label: Text('Call Emergency Services', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emergencyRed,
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _loadData(),
                                icon: Icon(Icons.local_hospital, color: Colors.white),
                                label: Text('Show Nearby Hospitals & Police', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkGolden,
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareLocation,
                                icon: Icon(Icons.share_location, color: Colors.white),
                                label: Text('Share My Location', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkGolden,
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.xl),
                        Text(
                          'Nearby Hospitals',
                          style: context.textStyles.titleMedium?.copyWith(color: AppColors.golden),
                        ),
                        SizedBox(height: AppSpacing.md),
                        ..._hospitals.map((hospital) {
                          final distance = _userLat != null && _userLon != null
                              ? hospital.distanceFrom(_userLat!, _userLon!)
                              : 0.0;
                          return EmergencyPlaceCard(
                            place: hospital,
                            distance: distance,
                            icon: Icons.local_hospital,
                          );
                        }),
                        SizedBox(height: AppSpacing.xl),
                        Text(
                          'Nearby Police Stations',
                          style: context.textStyles.titleMedium?.copyWith(color: AppColors.golden),
                        ),
                        SizedBox(height: AppSpacing.md),
                        ..._policeStations.map((station) {
                          final distance = _userLat != null && _userLon != null
                              ? station.distanceFrom(_userLat!, _userLon!)
                              : 0.0;
                          return EmergencyPlaceCard(
                            place: station,
                            distance: distance,
                            icon: Icons.local_police,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
                ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 6),
    );
  }
}

class EmergencyDialog extends StatelessWidget {
  final double? userLat;
  final double? userLon;

  const EmergencyDialog({super.key, this.userLat, this.userLon});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.brownCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Emergency Assistance',
              style: context.textStyles.titleLarge?.copyWith(color: AppColors.emergencyRed),
            ),
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  launchUrl(Uri.parse('tel:112'));
                  Navigator.pop(context);
                },
                icon: Icon(Icons.warning, color: Colors.white),
                label: Text('Call Emergency Services', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.local_hospital, color: Colors.white),
                label: Text('Show Nearby Hospitals & Police', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGolden,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (userLat != null && userLon != null) {
                    final locationUrl = 'https://www.google.com/maps?q=$userLat,$userLon';
                    final message = 'My current location: $locationUrl';
                    launchUrl(Uri.parse('sms:?body=${Uri.encodeComponent(message)}'));
                  }
                  Navigator.pop(context);
                },
                icon: Icon(Icons.share_location, color: Colors.white),
                label: Text('Share My Location', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGolden,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyPlaceCard extends StatelessWidget {
  final Place place;
  final double distance;
  final IconData icon;

  const EmergencyPlaceCard({
    super.key,
    required this.place,
    required this.distance,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.brownCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.emergencyRed),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  place.name,
                  style: context.textStyles.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: context.textStyles.bodySmall?.copyWith(color: AppColors.golden),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            place.address,
            style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
          ),
          if (place.phoneNumber != null) ...[
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:${place.phoneNumber}')),
                    icon: Icon(Icons.phone, color: Colors.white, size: 16),
                    label: Text('Call', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyRed,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final t = Uri.encodeComponent(place.name);
                      context.push('${AppRoutes.map}?lat=${place.latitude}&lon=${place.longitude}&title=$t&autoroute=true');
                    },
                    icon: Icon(Icons.directions, color: Colors.white, size: 16),
                    label: Text('Directions', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBrown, padding: EdgeInsets.symmetric(vertical: AppSpacing.sm)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
