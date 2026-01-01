import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/models/place.dart';
import 'package:wayfinder/services/place_service.dart';
import 'package:wayfinder/services/location_service.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:wayfinder/nav.dart';
import 'package:wayfinder/services/saved_place_service.dart';
import 'package:wayfinder/services/collection_service.dart';
import 'package:wayfinder/models/saved_place.dart';
import 'package:wayfinder/widgets/app_background.dart';
import 'package:wayfinder/widgets/live_image_header.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  final PlaceService _placeService = PlaceService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final SavedPlaceService _savedService = SavedPlaceService();
  final CollectionService _collectionService = CollectionService();
  
  List<Place> _restaurants = [];
  List<Place> _filteredRestaurants = [];
  bool _isLoading = true;
  double? _userLat;
  double? _userLon;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _savePlace(Place p) async {
    final userId = 'local_user';
    final sp = SavedPlace(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      placeId: p.id,
      placeName: p.name,
      address: p.address,
      latitude: p.latitude,
      longitude: p.longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _savedService.addSavedPlace(sp);
    final fav = await _collectionService.ensureDefaultFavorites(userId);
    await _collectionService.addPlaceToCollection(collectionId: fav.id, place: sp);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${fav.name}')));
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

    final restaurants = await _placeService.getPlacesByType(PlaceType.restaurant);
    
    if (_userLat != null && _userLon != null) {
      restaurants.sort((a, b) => 
        a.distanceFrom(_userLat!, _userLon!).compareTo(b.distanceFrom(_userLat!, _userLon!))
      );
    }

    setState(() {
      _restaurants = restaurants;
      _filteredRestaurants = restaurants;
      _isLoading = false;
    });
  }

  void _filterRestaurants(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRestaurants = _restaurants;
      } else {
        _filteredRestaurants = _restaurants.where((r) =>
          r.name.toLowerCase().contains(query.toLowerCase()) ||
          r.address.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Eat',
          style: context.textStyles.titleLarge?.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.refresh, color: AppColors.golden),
            label: Text('Refresh', style: TextStyle(color: AppColors.golden)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: AppGradientBackground(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: LiveImageHeader(images: const [
              'assets/images/Cozy_cafe_interior_brown_1767253936244.jpg',
              'assets/images/Street_food_market_crowd_orange_1767253931477.jpg',
              'assets/images/City_skyline_at_night_blue_1767253930156.jpg',
            ], height: 160),
          ),
          Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurants near you (live location). No default list.',
                  style: context.textStyles.bodyMedium?.copyWith(color: AppColors.lightGray),
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
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.searchBar,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterRestaurants,
                          decoration: InputDecoration(
                            hintText: 'Search food (e.g., biryani, dosa, cafe)',
                            border: InputBorder.none,
                            icon: Icon(Icons.search, color: Colors.white70),
                            hintStyle: context.textStyles.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          style: context.textStyles.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm + 4),
                      decoration: BoxDecoration(
                        color: AppColors.golden,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text('Search', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.golden))
                : _filteredRestaurants.isEmpty
                    ? Center(
                        child: Text(
                          'No restaurants found',
                          style: context.textStyles.bodyLarge?.copyWith(color: AppColors.lightGray),
                        ),
                      )
                     : ListView.builder(
                        padding: AppSpacing.paddingMd,
                        itemCount: _filteredRestaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = _filteredRestaurants[index];
                          final distance = _userLat != null && _userLon != null
                              ? restaurant.distanceFrom(_userLat!, _userLon!)
                              : 0.0;
                           return Dismissible(
                             key: ValueKey('rest_${restaurant.id}'),
                             direction: DismissDirection.endToStart,
                             background: Container(
                               alignment: Alignment.centerRight,
                               padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                               color: AppColors.golden,
                               child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.bookmark_add, color: Colors.black), SizedBox(width: 8), Text('Save', style: TextStyle(color: Colors.black))]),
                             ),
                             confirmDismiss: (_) async {
                               await _savePlace(restaurant);
                               return false; // keep the item
                             },
                             child: RestaurantCard(
                               restaurant: restaurant,
                               distance: distance,
                             ),
                           );
                        },
                      ),
          ),
        ],
      )),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final Place restaurant;
  final double distance;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.distance,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: context.textStyles.bodySmall?.copyWith(color: AppColors.golden),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.star, color: AppColors.golden, size: 14),
              SizedBox(width: 4),
              Text(
                '—',
                style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
              ),
              SizedBox(width: AppSpacing.md),
              Icon(Icons.location_on, color: AppColors.lightGray, size: 14),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  restaurant.address,
                  style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (restaurant.category != null) ...[
            SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.restaurant, color: AppColors.lightGray, size: 14),
                SizedBox(width: 4),
                Text(
                  restaurant.category!,
                  style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray),
                ),
              ],
            ),
          ],
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final title = Uri.encodeComponent(restaurant.name);
                    context.push('${AppRoutes.map}?lat=${restaurant.latitude}&lon=${restaurant.longitude}&title=$title&autoroute=true');
                  },
                  icon: Icon(Icons.directions, color: Colors.white, size: 16),
                  label: Text('Directions', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('${AppRoutes.transport}?destination=${restaurant.name}'),
                  icon: Icon(Icons.directions_bus, color: Colors.black, size: 16),
                  label: Text('Bus Guidance', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.golden,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.brownCard,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md))),
                    builder: (_) => Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Icon(Icons.local_taxi, color: AppColors.golden), SizedBox(width: 8), Text('Book ride', style: context.textStyles.titleMedium?.copyWith(color: Colors.white))]),
                        ListTile(
                          leading: Icon(Icons.directions_car, color: Colors.white),
                          title: Text('Uber', style: TextStyle(color: Colors.white)),
                          onTap: () => launchUrl(Uri.parse('uber://?action=setPickup&pickup=my_location&dropoff[latitude]=${restaurant.latitude}&dropoff[longitude]=${restaurant.longitude}'), mode: LaunchMode.externalApplication),
                        ),
                        ListTile(
                          leading: Icon(Icons.local_taxi, color: Colors.white),
                          title: Text('Ola', style: TextStyle(color: Colors.white)),
                          onTap: () => launchUrl(Uri.parse('olacabs://app/launch?lat=0&lng=0&drop_lat=${restaurant.latitude}&drop_lng=${restaurant.longitude}'), mode: LaunchMode.externalApplication),
                        ),
                      ]),
                    ),
                  );
                },
                icon: Icon(Icons.local_taxi, color: Colors.black, size: 16),
                label: Text('Rides', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.golden,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
