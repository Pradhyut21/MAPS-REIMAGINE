class TravelAlert {
  final String id;
  final String userId;
  final String placeName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TravelAlert({
    required this.id,
    required this.userId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TravelAlert.fromJson(Map<String, dynamic> json) => TravelAlert(
    id: json['id'] as String,
    userId: json['userId'] as String,
    placeName: json['placeName'] as String,
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    radiusMeters: json['radiusMeters'] as double,
    isActive: json['isActive'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'placeName': placeName,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  TravelAlert copyWith({
    String? id,
    String? userId,
    String? placeName,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TravelAlert(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    placeName: placeName ?? this.placeName,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
