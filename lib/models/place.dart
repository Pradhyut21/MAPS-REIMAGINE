import 'dart:math';

enum PlaceType { restaurant, attraction, hospital, police, general }

class Place {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final PlaceType type;
  final String? category;
  final double? rating;
  final String? phoneNumber;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.category,
    this.rating,
    this.phoneNumber,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    type: PlaceType.values.firstWhere((e) => e.name == json['type']),
    category: json['category'] as String?,
    rating: json['rating'] as double?,
    phoneNumber: json['phoneNumber'] as String?,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'type': type.name,
    'category': category,
    'rating': rating,
    'phoneNumber': phoneNumber,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Place copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    PlaceType? type,
    String? category,
    double? rating,
    String? phoneNumber,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Place(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    type: type ?? this.type,
    category: category ?? this.category,
    rating: rating ?? this.rating,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  double distanceFrom(double lat, double lon) {
    const double earthRadiusKm = 6371;
    final dLat = _degreesToRadians(latitude - lat);
    final dLon = _degreesToRadians(longitude - lon);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat)) * cos(_degreesToRadians(latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;
}
