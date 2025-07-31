class Course {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final bool isActive;

  Course({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.isActive = true,
  });

  factory Course.fromMap(Map<String, dynamic> data, String id) {
    return Course(
      id: id,
      name: data['name'] ?? 'Unknown Course',
      description: data['description'],
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt']?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  Course copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
