import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:wayfinder/services/location_service.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/widgets/app_background.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  final _location = LocationService();
  double? _lat;
  double? _lon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _location.getCurrentLocation();
    if (p != null) {
      setState(() {
        _lat = p.latitude;
        _lon = p.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offline Mode', style: context.textStyles.titleLarge),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: AppGradientBackground(
        child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Download area for offline maps', style: context.textStyles.headlineSmall),
          SizedBox(height: AppSpacing.sm),
          Text('Choose a radius around your current location to cache map tiles for use without internet. Coming soon.', style: context.textStyles.bodyMedium),
          SizedBox(height: AppSpacing.lg),
          Row(children: [
            Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 16),
            SizedBox(width: AppSpacing.xs),
            Text(_lat != null ? '${_lat!.toStringAsFixed(4)}, ${_lon!.toStringAsFixed(4)}' : 'Locating...'),
          ]),
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Area selection', style: context.textStyles.titleMedium),
              SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: Slider(value: 5, min: 1, max: 50, divisions: 49, onChanged: (_) {})),
                SizedBox(width: AppSpacing.sm),
                Text('5 km'),
              ]),
              SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {}, icon: Icon(Icons.download), label: Text('Prepare download (coming soon)'))),
            ]),
          ),
        ]),
      ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
