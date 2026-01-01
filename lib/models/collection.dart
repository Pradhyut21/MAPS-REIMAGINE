class Collection {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Collection({required this.id, required this.userId, required this.name, required this.createdAt, required this.updatedAt});

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Collection copyWith({String? id, String? userId, String? name, DateTime? createdAt, DateTime? updatedAt}) => Collection(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
