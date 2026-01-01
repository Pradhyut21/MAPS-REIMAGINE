import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/nav.dart';
import 'package:intl/intl.dart';
import 'package:wayfinder/widgets/live_image_header.dart';
import 'package:wayfinder/widgets/glass_container.dart';
import 'package:wayfinder/widgets/tilt_container.dart';
import 'package:wayfinder/widgets/app_background.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage.build');
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final time = DateFormat('h:mm a').format(DateTime.now());

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, User',
                            style: context.textStyles.titleLarge?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.white, size: 16),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            time,
                            style: context.textStyles.bodyMedium?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(padding: AppSpacing.horizontalMd, child: LiveImageHeader(images: const [
                  'assets/images/City_skyline_at_night_blue_1767253930156.jpg',
                  'assets/images/Tropical_beach_palms_aerial_turquoise_1767253935055.jpg',
                  'assets/images/Mountain_landscape_sunrise_green_1767253933737.jpg',
                ])),
                SizedBox(height: AppSpacing.md),
                Padding(padding: AppSpacing.horizontalMd, child: SearchBarWidget(onTap: () => context.push(AppRoutes.map))),
                SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: AppSpacing.horizontalMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: context.textStyles.titleMedium?.copyWith(color: AppColors.golden),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(children: [
                        Expanded(child: QuickActionCard(icon: Icons.travel_explore, label: 'Explore Map', onTap: () => context.push(AppRoutes.map))),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: QuickActionCard(icon: Icons.ramen_dining, label: 'Eat & Drink', onTap: () => context.push(AppRoutes.restaurants))),
                      ]),
                      SizedBox(height: AppSpacing.md),
                      Row(children: [
                        Expanded(child: QuickActionCard(icon: Icons.directions_transit_filled, label: 'Transport', onTap: () => context.push(AppRoutes.transport))),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: QuickActionCard(icon: Icons.emergency_share, label: 'Emergency', color: AppColors.emergencyRed, onTap: () => context.push(AppRoutes.emergency))),
                      ]),
                      SizedBox(height: AppSpacing.md),
                      Row(children: [Expanded(child: QuickActionCard(icon: Icons.collections_bookmark_outlined, label: 'Collections', onTap: () => context.push(AppRoutes.collections))), SizedBox(width: AppSpacing.md), Expanded(child: QuickActionCard(icon: Icons.cloud_off, label: 'Offline', onTap: () => context.push(AppRoutes.offline)))]),
                      SizedBox(height: AppSpacing.md),
                      Row(children: [Expanded(child: QuickActionCard(icon: Icons.luggage, label: 'Trip Packages', onTap: () => context.push(AppRoutes.trips))), SizedBox(width: AppSpacing.md), Expanded(child: QuickActionCard(icon: Icons.smart_toy_outlined, label: 'AI Assistant', onTap: () => context.push(AppRoutes.ai)))]),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: AppSpacing.horizontalMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Browse by type', style: context.textStyles.titleMedium?.copyWith(color: AppColors.golden)),
                      SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: const [
                          TypeChipButton(icon: Icons.restaurant, label: 'Restaurants', route: AppRoutes.restaurants),
                          TypeChipButton(icon: Icons.local_cafe, label: 'Cafes', route: AppRoutes.restaurants),
                          TypeChipButton(icon: Icons.hotel, label: 'Hotels', route: AppRoutes.map),
                          TypeChipButton(icon: Icons.local_hospital, label: 'Hospitals', route: AppRoutes.emergency),
                          TypeChipButton(icon: Icons.local_atm, label: 'ATMs', route: AppRoutes.map),
                          TypeChipButton(icon: Icons.local_gas_station, label: 'Fuel', route: AppRoutes.map),
                          TypeChipButton(icon: Icons.park, label: 'Parks', route: AppRoutes.attractions),
                          TypeChipButton(icon: Icons.medication, label: 'Pharmacies', route: AppRoutes.emergency),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  final VoidCallback onTap;

  const SearchBarWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.white70, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Search for places, restaurants, or landmarks...',
              style: context.textStyles.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgTint = (color == null) ? Colors.white.withValues(alpha: 0.06) : color!.withValues(alpha: 0.9);
    final iconColor = (color == null) ? AppColors.golden : Colors.white; // ensure high contrast on colored cards
    return TiltContainer(
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: AppSpacing.paddingLg,
          tint: bgTint,
          child: Column(children: [
            Icon(icon, color: iconColor, size: 32),
            SizedBox(height: AppSpacing.sm),
            Text(label, textAlign: TextAlign.center, style: context.textStyles.labelLarge?.copyWith(color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}

class TypeChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const TypeChipButton({super.key, required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: AppColors.golden),
          SizedBox(width: AppSpacing.xs),
          Text(label, style: context.textStyles.labelLarge?.copyWith(color: Colors.white)),
        ]),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBrown,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavBarItem(
                icon: Icons.home_filled,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => context.go(AppRoutes.home),
              ),
              NavBarItem(
                icon: Icons.travel_explore,
                label: 'Map',
                isActive: currentIndex == 1,
                onTap: () => context.push(AppRoutes.map),
              ),
              NavBarItem(
                icon: Icons.ramen_dining,
                label: 'Eat',
                isActive: currentIndex == 2,
                onTap: () => context.push(AppRoutes.restaurants),
              ),
              NavBarItem(
                icon: Icons.tour,
                label: 'Go',
                isActive: currentIndex == 3,
                onTap: () => context.push(AppRoutes.attractions),
              ),
              NavBarItem(
                icon: Icons.directions_transit_filled,
                label: 'Bus',
                isActive: currentIndex == 4,
                onTap: () => context.push(AppRoutes.transport),
              ),
              NavBarItem(
                icon: Icons.smart_toy,
                label: 'AI',
                isActive: currentIndex == 5,
                onTap: () => context.push(AppRoutes.ai),
              ),
              NavBarItem(
                icon: Icons.emergency,
                label: 'Emergency',
                isActive: currentIndex == 6,
                color: AppColors.emergencyRed,
                onTap: () => context.push(AppRoutes.emergency),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const NavBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? (isActive ? AppColors.golden : Colors.white);
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: itemColor, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(color: itemColor, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
