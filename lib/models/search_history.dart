class SearchHistory {
  final String id;
  final String userId;
  final String searchQuery;
  final DateTime createdAt;

  SearchHistory({
    required this.id,
    required this.userId,
    required this.searchQuery,
    required this.createdAt,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) => SearchHistory(
    id: json['id'] as String,
    userId: json['userId'] as String,
    searchQuery: json['searchQuery'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'searchQuery': searchQuery,
    'createdAt': createdAt.toIso8601String(),
  };

  SearchHistory copyWith({
    String? id,
    String? userId,
    String? searchQuery,
    DateTime? createdAt,
  }) => SearchHistory(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    searchQuery: searchQuery ?? this.searchQuery,
    createdAt: createdAt ?? this.createdAt,
  );
}
