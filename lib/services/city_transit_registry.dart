import 'package:flutter/foundation.dart';

/// Basic bounding-box based city detection with known public bus operators.
/// This helps bias results toward the correct agency (e.g., BMTC in Bengaluru).
class CityTransitContext {
  final String cityName;
  final String operatorName; // e.g., BMTC, DTC, MTC, BEST, TSRTC, WBTC
  final String? osmNetworkTag; // common OSM network tag for route relations
  final List<String> majorHubs; // common hubs/stands

  CityTransitContext({required this.cityName, required this.operatorName, this.osmNetworkTag, this.majorHubs = const []});
}

class CityTransitRegistry {
  /// Very lightweight bbox definitions for major Indian capitals/metros.
  /// Lat: south..north, Lon: west..east
  static final List<_CityBox> _boxes = [
    _CityBox(
      name: 'Bengaluru',
      operatorName: 'BMTC',
      osmNetwork: 'BMTC',
      south: 12.80, north: 13.20, west: 77.40, east: 77.80,
      hubs: ['Kempegowda (Majestic) Bus Station', 'Shivajinagar', 'KR Market', 'Shantinagar'],
    ),
    _CityBox(
      name: 'Delhi',
      operatorName: 'DTC',
      osmNetwork: 'DTC',
      south: 28.40, north: 28.90, west: 76.80, east: 77.40,
      hubs: ['Kashmere Gate ISBT', 'Sarai Kale Khan ISBT', 'Anand Vihar ISBT'],
    ),
    _CityBox(
      name: 'Chennai',
      operatorName: 'MTC',
      osmNetwork: 'MTC',
      south: 12.90, north: 13.20, west: 80.10, east: 80.40,
      hubs: ['Puratchi Thalaivar Dr. M.G.R. Bus Terminus (CMBT)', 'Broadway'],
    ),
    _CityBox(
      name: 'Hyderabad',
      operatorName: 'TSRTC',
      osmNetwork: 'TSRTC',
      south: 17.20, north: 17.60, west: 78.20, east: 78.70,
      hubs: ['MGBS', 'JBS Secunderabad'],
    ),
    _CityBox(
      name: 'Kolkata',
      operatorName: 'WBTC',
      osmNetwork: 'WBTC',
      south: 22.30, north: 22.70, west: 88.20, east: 88.50,
      hubs: ['Esplanade', 'Howrah'],
    ),
    _CityBox(
      name: 'Mumbai',
      operatorName: 'BEST',
      osmNetwork: 'BEST',
      south: 18.85, north: 19.30, west: 72.75, east: 73.10,
      hubs: ['CST', 'Dadar', 'Andheri'],
    ),
    _CityBox(
      name: 'Thiruvananthapuram',
      operatorName: 'KSRTC (City)',
      osmNetwork: 'KSRTC',
      south: 8.40, north: 8.65, west: 76.85, east: 77.10,
      hubs: ['East Fort'],
    ),
    _CityBox(
      name: 'Bhopal',
      operatorName: 'BCLL',
      osmNetwork: 'BCLL',
      south: 23.15, north: 23.35, west: 77.30, east: 77.60,
      hubs: ['ISBT Bhopal'],
    ),
  ];

  static CityTransitContext? detect(double lat, double lon) {
    try {
      for (final b in _boxes) {
        if (lat >= b.south && lat <= b.north && lon >= b.west && lon <= b.east) {
          return CityTransitContext(cityName: b.name, operatorName: b.operatorName, osmNetworkTag: b.osmNetwork, majorHubs: b.hubs);
        }
      }
    } catch (e) {
      debugPrint('CityTransitRegistry.detect error: $e');
    }
    return null;
  }
}

class _CityBox {
  final String name;
  final String operatorName;
  final String? osmNetwork;
  final double south, north, west, east;
  final List<String> hubs;

  _CityBox({required this.name, required this.operatorName, required this.south, required this.north, required this.west, required this.east, this.osmNetwork, this.hubs = const []});
}
