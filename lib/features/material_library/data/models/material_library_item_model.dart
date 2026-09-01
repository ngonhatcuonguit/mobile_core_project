import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';

class MaterialLibraryItemModel extends MaterialLibraryItem {
  const MaterialLibraryItemModel({
    super.id,
    super.catalogCode,
    required super.name,
    required super.price,
    required super.unit,
    required super.type,
    super.length,
    super.width,
    super.height,
  });

  factory MaterialLibraryItemModel.fromEntity(MaterialLibraryItem entity) {
    return MaterialLibraryItemModel(
      id: entity.id,
      catalogCode: entity.catalogCode,
      name: entity.name,
      price: entity.price,
      unit: entity.unit,
      type: entity.type,
      length: entity.length,
      width: entity.width,
      height: entity.height,
    );
  }

  factory MaterialLibraryItemModel.fromDatabaseMap(
    Map<String, Object?> map,
  ) {
    return MaterialLibraryItemModel(
      id: map['id'] as int?,
      catalogCode: map['catalog_code'] as String?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
      type: LibraryItemType.fromDatabaseValue(map['type'] as String),
      length: (map['length'] as num?)?.toDouble(),
      width: (map['width'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> toDatabaseMap({bool includeId = false}) {
    return {
      if (includeId && id != null) 'id': id,
      'catalog_code': catalogCode,
      'name': name.trim(),
      'price': price,
      'unit': unit.trim(),
      'type': type.databaseValue,
      'length': unit == 'piece' ? length : null,
      'width': unit == 'piece' ? width : null,
      'height': unit == 'piece' ? height : null,
    };
  }
}
