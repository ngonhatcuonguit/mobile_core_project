import 'package:equatable/equatable.dart';

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

class MaterialLibraryItem extends Equatable {
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

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        unit,
        type,
        length,
        width,
        height,
      ];
}
