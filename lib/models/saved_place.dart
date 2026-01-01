class SavedPlace {
  final String id;
  final String userId;
  final String placeId;
  final String placeName;
  final String address;
  final double latitude;
  final double longitude;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedPlace({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
    id: json['id'] as String,
    userId: json['userId'] as String,
    placeId: json['placeId'] as String,
    placeName: json['placeName'] as String,
    address: json['address'] as String,
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'placeId': placeId,
    'placeName': placeName,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  SavedPlace copyWith({
    String? id,
    String? userId,
    String? placeId,
    String? placeName,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavedPlace(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    placeId: placeId ?? this.placeId,
    placeName: placeName ?? this.placeName,
    address: address ?? this.address,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
