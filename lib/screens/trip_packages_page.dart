import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/widgets/app_background.dart';
import 'package:wayfinder/nav.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:wayfinder/widgets/live_image_header.dart';
import 'package:wayfinder/services/auth_service.dart';

class TripPackagesPage extends StatefulWidget {
  const TripPackagesPage({super.key});

  @override
  State<TripPackagesPage> createState() => _TripPackagesPageState();
}

class _TripPackagesPageState extends State<TripPackagesPage> {
  @override
  void initState() {
    super.initState();
    // gate: require login to access packages (guests are allowed)
    Future.microtask(() async {
      final loggedIn = await AuthService.instance.isLoggedIn();
      if (!mounted) return;
      if (!loggedIn) context.go('${AppRoutes.login}?redirect=${Uri.encodeComponent(AppRoutes.trips)}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final packages = [
      _TripPackage(title: 'Weekend in Mysuru', days: 2, price: 2999, highlights: ['Mysore Palace', 'Brindavan Gardens', 'Local food tour'], destinationLat: 12.2958, destinationLon: 76.6394),
      _TripPackage(title: 'Coorg Nature Escape', days: 3, price: 6999, highlights: ['Abbey Falls', 'Coffee estates', 'Raja’s Seat'], destinationLat: 12.3375, destinationLon: 75.8069),
      _TripPackage(title: 'Temple Trail: Srirangapatna', days: 1, price: 1999, highlights: ['Ranganathaswamy Temple', 'Daria Daulat Bagh'], destinationLat: 12.4222, destinationLon: 76.6927),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
        title: Text('Trip Packages', style: context.textStyles.titleLarge?.copyWith(color: Colors.white)),
      ),
      body: AppGradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: LiveImageHeader(images: const [
                  'assets/images/3D_travel_skyline_gradient_sunset_orange_1767254945456.png',
                  'assets/images/Isometric_3D_world_map_with_location_pins_neon_turquoise_1767255105320.png',
                  'assets/images/3D_isometric_suitcase_passport_boarding_pass_blue_1767255114193.png',
                ], height: 160),
              ),
            ),
            SliverPadding(
              padding: AppSpacing.paddingMd,
              sliver: SliverList.separated(
                itemCount: packages.length,
                itemBuilder: (context, i) => _TripCard(pkg: packages[i]),
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}

class _TripPackage {
  final String title;
  final int days;
  final int price; // INR
  final List<String> highlights;
  final double destinationLat;
  final double destinationLon;
  const _TripPackage({required this.title, required this.days, required this.price, required this.highlights, required this.destinationLat, required this.destinationLon});
}

class _TripCard extends StatelessWidget {
  final _TripPackage pkg;
  const _TripCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.brownCard, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.flight_takeoff, color: AppColors.golden),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(pkg.title, style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold))),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(20)),
              child: Text('${pkg.days}D', style: context.textStyles.labelSmall?.copyWith(color: Colors.white)),
            ),
          ]),
          SizedBox(height: AppSpacing.sm),
          Wrap(spacing: 8, runSpacing: 8, children: pkg.highlights.map((h) => _chip(context, h)).toList()),
          SizedBox(height: AppSpacing.md),
          Row(children: [
            Text('₹${pkg.price}', style: context.textStyles.titleSmall?.copyWith(color: AppColors.golden, fontWeight: FontWeight.w700)),
            Text(' / person', style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray)),
            Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                final title = Uri.encodeComponent(pkg.title);
                context.push('${AppRoutes.map}?lat=${pkg.destinationLat}&lon=${pkg.destinationLon}&title=$title&autoroute=false');
              },
              icon: Icon(Icons.map, color: Colors.black),
              label: Text('View on Map', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, shape: StadiumBorder()),
            ),
          ]),
          SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showComingSoon(context),
                icon: Icon(Icons.shopping_bag, color: AppColors.golden),
                label: Text('Book Package', style: TextStyle(color: AppColors.golden)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.golden), shape: StadiumBorder()),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showComingSoon(context),
                icon: Icon(Icons.info_outline, color: AppColors.golden),
                label: Text('Details', style: TextStyle(color: AppColors.golden)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.golden), shape: StadiumBorder()),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(BuildContext context, String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.darkBrown, borderRadius: BorderRadius.circular(22)),
        child: Text(text, style: context.textStyles.labelSmall?.copyWith(color: Colors.white)),
      );

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coming soon with Mobbin-inspired flows ✨')));
  }
}
