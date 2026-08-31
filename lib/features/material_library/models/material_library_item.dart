enum LibraryItemType {
  material,
  labor;

  String get databaseValue => name;

  static LibraryItemType fromDatabaseValue(String value) {
    return LibraryItemType.values.firstWhere(
      (type) => type.databaseValue == value,
      orElse: () => LibraryItemType.material,
    );
  }
}

class MaterialLibraryItem {
  const MaterialLibraryItem({
    this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.type,
  });

  final int? id;
  final String name;
  final double price;
  final String unit;
  final LibraryItemType type;

  MaterialLibraryItem copyWith({
    int? id,
    String? name,
    double? price,
    String? unit,
    LibraryItemType? type,
  }) {
    return MaterialLibraryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      type: type ?? this.type,
    );
  }

  Map<String, Object?> toDatabaseMap({bool includeId = false}) {
    return {
      if (includeId && id != null) 'id': id,
      'name': name.trim(),
      'price': price,
      'unit': unit.trim(),
      'type': type.databaseValue,
    };
  }

  factory MaterialLibraryItem.fromDatabaseMap(Map<String, Object?> map) {
    return MaterialLibraryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
      type: LibraryItemType.fromDatabaseValue(map['type'] as String),
    );
  }
}
