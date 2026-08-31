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
    this.length,
    this.width,
    this.height,
  });

  final int? id;
  final String name;
  final double price;
  final String unit;
  final LibraryItemType type;
  final double? length;
  final double? width;
  final double? height;

  bool get hasPieceDimensions =>
      unit == 'piece' && length != null && width != null && height != null;

  MaterialLibraryItem copyWith({
    int? id,
    String? name,
    double? price,
    String? unit,
    LibraryItemType? type,
    double? length,
    double? width,
    double? height,
  }) {
    return MaterialLibraryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, Object?> toDatabaseMap({bool includeId = false}) {
    return {
      if (includeId && id != null) 'id': id,
      'name': name.trim(),
      'price': price,
      'unit': unit.trim(),
      'type': type.databaseValue,
      'length': unit == 'piece' ? length : null,
      'width': unit == 'piece' ? width : null,
      'height': unit == 'piece' ? height : null,
    };
  }

  factory MaterialLibraryItem.fromDatabaseMap(Map<String, Object?> map) {
    return MaterialLibraryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
      type: LibraryItemType.fromDatabaseValue(map['type'] as String),
      length: (map['length'] as num?)?.toDouble(),
      width: (map['width'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
    );
  }
}
